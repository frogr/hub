require 'rails_helper'

RSpec.describe StripeWebhookService do
  let(:event) { Stripe::Event.construct_from(event_data) }
  let(:service) { described_class.new(event) }

  describe '#process' do
    context 'with checkout.session.completed event' do
      let(:user) { create(:user) }
      let(:plan) { create(:plan, :with_stripe_price) }
      let(:event_data) do
        {
          type: 'checkout.session.completed',
          data: {
            object: {
              mode: 'subscription',
              subscription: 'sub_123',
              metadata: {
                user_id: user.id.to_s,
                plan_id: plan.id.to_s
              }
            }
          }
        }
      end

      it 'delegates to CheckoutSessionCompletedHandler' do
        expect_any_instance_of(StripeWebhook::CheckoutSessionCompletedHandler)
          .to receive(:handle)

        service.process
      end

      it 'creates subscription through SubscriptionService' do
        subscription_service = instance_double(SubscriptionService)
        expect(SubscriptionService).to receive(:new).with(user).and_return(subscription_service)
        expect(subscription_service).to receive(:create_subscription).with('sub_123')

        service.process
      end

      context 'when user not found' do
        before { event.data.object.metadata.user_id = '999999' }

        it 'does not create subscription' do
          expect(SubscriptionService).not_to receive(:new)
          service.process
        end
      end

      context 'when mode is not subscription' do
        before { event.data.object.mode = 'payment' }

        it 'does not create subscription' do
          expect(SubscriptionService).not_to receive(:new)
          service.process
        end
      end
    end

    context 'with customer.subscription.updated event' do
      let(:subscription) { create(:subscription, :with_stripe_ids) }
      let(:event_data) do
        {
          type: 'customer.subscription.updated',
          data: {
            object: {
              id: subscription.stripe_subscription_id,
              status: 'past_due',
              current_period_end: 2.weeks.from_now.to_i,
              cancel_at_period_end: true
            }
          }
        }
      end

      it 'delegates to SubscriptionUpdatedHandler' do
        expect_any_instance_of(StripeWebhook::SubscriptionUpdatedHandler)
          .to receive(:handle)

        service.process
      end

      it 'updates subscription attributes' do
        service.process
        subscription.reload

        expect(subscription.status).to eq('past_due')
        expect(subscription.cancel_at_period_end).to be true
        expect(subscription.current_period_end).to be_between(13.days.from_now, 15.days.from_now)
      end

      context 'when subscription not found' do
        let(:event_data) do
          {
            type: 'customer.subscription.updated',
            data: {
              object: {
                id: 'sub_nonexistent',
                status: 'active',
                current_period_end: 2.weeks.from_now.to_i,
                cancel_at_period_end: false
              }
            }
          }
        end

        it 'does not raise error' do
          expect { service.process }.not_to raise_error
        end
      end
    end

    context 'with customer.subscription.deleted event' do
      let(:subscription) { create(:subscription, :with_stripe_ids, status: 'active') }
      let(:event_data) do
        {
          type: 'customer.subscription.deleted',
          data: {
            object: {
              id: subscription.stripe_subscription_id
            }
          }
        }
      end

      it 'delegates to SubscriptionDeletedHandler' do
        expect_any_instance_of(StripeWebhook::SubscriptionDeletedHandler)
          .to receive(:handle)

        service.process
      end

      it 'marks subscription as canceled' do
        service.process
        expect(subscription.reload.status).to eq('canceled')
      end
    end

    context 'with invoice.payment_failed event' do
      let(:subscription) { create(:subscription, :with_stripe_ids) }
      let(:event_data) do
        {
          type: 'invoice.payment_failed',
          data: {
            object: {
              subscription: subscription.stripe_subscription_id
            }
          }
        }
      end

      it 'delegates to PaymentFailedHandler' do
        expect_any_instance_of(StripeWebhook::PaymentFailedHandler)
          .to receive(:handle)

        service.process
      end

      it 'logs payment failure' do
        expect(Rails.logger).to receive(:warn)
          .with("Payment failed for subscription #{subscription.id}")

        service.process
      end
    end

    context 'with unhandled event type' do
      let(:event_data) do
        {
          type: 'unhandled.event',
          data: { object: {} }
        }
      end

      it 'logs unhandled event' do
        expect(Rails.logger).to receive(:info)
          .with('Unhandled Stripe event type: unhandled.event')

        service.process
      end
    end

    context 'error handling' do
      let(:event_data) do
        {
          type: 'checkout.session.completed',
          data: {
            object: {
              mode: 'subscription',
              subscription: 'sub_123',
              metadata: { user_id: '1' }
            }
          }
        }
      end

      it 'logs errors and re-raises in test environment' do
        allow(User).to receive(:find_by).and_raise(StandardError.new('Database error'))

        expect(Rails.logger).to receive(:error)
          .with('Error handling Stripe webhook checkout.session.completed: Database error')

        expect { service.process }.to raise_error(StandardError, 'Database error')
      end

      it 'logs errors without raising in non-test environment' do
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(User).to receive(:find_by).and_raise(StandardError.new('Database error'))

        expect(Rails.logger).to receive(:error)
          .with('Error handling Stripe webhook checkout.session.completed: Database error')

        expect { service.process }.not_to raise_error
      end
    end
  end
end
