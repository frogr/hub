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

      it 'creates subscription through SubscriptionService' do
        subscription_service = instance_double(SubscriptionService)
        expect(SubscriptionService).to receive(:new).with(user).and_return(subscription_service)
        expect(subscription_service).to receive(:create_subscription).with('sub_123')

        result = service.process
        expect(result[:handled]).to be true
      end

      context 'when user not found' do
        before { event.data.object.metadata.user_id = '999999' }

        it 'does not create subscription' do
          expect(SubscriptionService).not_to receive(:new)
          result = service.process
          expect(result[:handled]).to be false
        end
      end

      context 'when mode is not subscription' do
        before { event.data.object.mode = 'payment' }

        it 'does not create subscription' do
          expect(SubscriptionService).not_to receive(:new)
          result = service.process
          expect(result[:handled]).to be false
        end
      end
    end

    context 'with customer.subscription.updated event' do
      let(:subscription) { create(:subscription) }
      let(:event_data) do
        {
          type: 'customer.subscription.updated',
          data: {
            object: {
              id: subscription.stripe_subscription_id,
              customer: 'cus_123',
              status: 'canceled',
              current_period_start: Time.now.to_i,
              current_period_end: 1.day.from_now.to_i,
              cancel_at_period_end: true,
              canceled_at: nil,
              trial_start: nil,
              trial_end: nil,
              items: {
                data: [{
                  price: { id: 'price_123' }
                }]
              },
              metadata: {},
              created: Time.now.to_i
            }
          }
        }
      end

      it 'updates subscription attributes' do
        result = service.process
        expect(result[:handled]).to be true
        
        subscription.reload
        expect(subscription.status).to eq('canceled')
        expect(subscription.cancel_at_period_end).to be true
      end

      context 'when subscription not found' do
        let(:event_data) do
          {
            type: 'customer.subscription.updated',
            data: {
              object: {
                id: 'sub_unknown',
                customer: 'cus_123',
                status: 'canceled',
                current_period_start: Time.now.to_i,
                current_period_end: 1.day.from_now.to_i,
                cancel_at_period_end: true,
                canceled_at: nil,
                trial_start: nil,
                trial_end: nil,
                items: {
                  data: [{
                    price: { id: 'price_123' }
                  }]
                },
                metadata: {},
                created: Time.now.to_i
              }
            }
          }
        end

        it 'does not raise error' do
          expect { service.process }.not_to raise_error
          result = service.process
          expect(result[:handled]).to be false
        end
      end
    end

    context 'with customer.subscription.deleted event' do
      let(:subscription) { create(:subscription, status: 'active') }
      let(:event_data) do
        {
          type: 'customer.subscription.deleted',
          data: {
            object: {
              id: subscription.stripe_subscription_id,
              customer: 'cus_123',
              status: 'canceled',
              current_period_start: Time.now.to_i,
              current_period_end: Time.now.to_i,
              cancel_at_period_end: false,
              canceled_at: nil,
              trial_start: nil,
              trial_end: nil,
              items: {
                data: [{
                  price: { id: 'price_123' }
                }]
              },
              metadata: {},
              created: Time.now.to_i
            }
          }
        }
      end

      it 'marks subscription as canceled' do
        result = service.process
        expect(result[:handled]).to be true
        
        subscription.reload
        expect(subscription.status).to eq('canceled')
      end
    end

    context 'with invoice.payment_failed event' do
      let(:subscription) { create(:subscription, status: 'active') }
      let(:user) { subscription.user }
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

      it 'updates subscription to past_due and sends email' do
        expect(UserMailer).to receive(:payment_failed).with(user).and_return(double(deliver_later: true))
        
        result = service.process
        expect(result[:handled]).to be true
        
        subscription.reload
        expect(subscription.status).to eq('past_due')
      end
    end

    context 'with unhandled event type' do
      let(:event_data) do
        {
          type: 'some.unhandled.event',
          data: { object: {} }
        }
      end

      it 'logs unhandled event' do
        expect(Rails.logger).to receive(:info).with(/Unhandled event type/)
        
        result = service.process
        expect(result[:handled]).to be false
      end
    end

    context 'error handling' do
      let(:event_data) do
        {
          type: 'customer.subscription.updated',
          data: { object: { id: 'sub_123' } }
        }
      end

      it 'logs errors and re-raises in test environment' do
        allow_any_instance_of(StripeDomain::WebhookHandler).to receive(:handle).and_raise(StandardError, 'Test error')
        
        expect(Rails.logger).to receive(:error).with(/Error handling Stripe webhook/)
        expect { service.process }.to raise_error(StandardError, 'Test error')
      end

      it 'logs errors without raising in non-test environment' do
        allow(Rails.env).to receive(:test?).and_return(false)
        allow_any_instance_of(StripeDomain::WebhookHandler).to receive(:handle).and_raise(StandardError, 'Test error')
        
        expect(Rails.logger).to receive(:error).with(/Error handling Stripe webhook/)
        
        result = service.process
        expect(result[:handled]).to be false
        expect(result[:error]).to eq('Test error')
      end
    end
  end
end