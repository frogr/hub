require 'rails_helper'

RSpec.describe SubscriptionService, type: :service do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, :with_stripe_price) }
  let(:service) { described_class.new(user, plan) }

  describe '#initialize' do
    it 'sets the user and plan' do
      expect(service.user).to eq(user)
      expect(service.plan).to eq(plan)
    end

    it 'allows nil plan' do
      service_without_plan = described_class.new(user)
      expect(service_without_plan.user).to eq(user)
      expect(service_without_plan.plan).to be_nil
    end
  end

  describe '#create_checkout_session' do
    let(:success_url) { 'https://example.com/success' }
    let(:cancel_url) { 'https://example.com/cancel' }
    let(:stripe_customer) { double('Stripe::Customer', id: 'cus_123') }

    context 'when plan is nil' do
      let(:service) { described_class.new(user, nil) }

      it 'returns nil' do
        expect(service.create_checkout_session(success_url: success_url, cancel_url: cancel_url)).to be_nil
      end
    end

    context 'when plan has no stripe_price_id' do
      let(:plan) { create(:plan, stripe_price_id: nil) }

      it 'returns nil' do
        expect(service.create_checkout_session(success_url: success_url, cancel_url: cancel_url)).to be_nil
      end
    end

    context 'when plan has stripe_price_id' do
      before do
        allow_any_instance_of(StripeCustomerService).to receive(:find_or_create).and_return(stripe_customer)
      end

      context 'without trial period' do
        it 'creates checkout session without trial data' do
          checkout_session = double('Stripe::Checkout::Session', url: 'https://checkout.stripe.com/pay/cs_123')

          expect(Stripe::Checkout::Session).to receive(:create).with({
            customer: 'cus_123',
            payment_method_types: [ 'card' ],
            line_items: [ {
              price: plan.stripe_price_id,
              quantity: 1
            } ],
            mode: 'subscription',
            success_url: success_url,
            cancel_url: cancel_url,
            metadata: {
              user_id: user.id,
              plan_id: plan.id
            }
          }).and_return(checkout_session)

          result = service.create_checkout_session(success_url: success_url, cancel_url: cancel_url)
          expect(result).to eq(checkout_session)
        end
      end

      context 'with trial period' do
        let(:plan) { create(:plan, :with_stripe_price, :with_trial) }

        it 'creates checkout session with trial data' do
          checkout_session = double('Stripe::Checkout::Session', url: 'https://checkout.stripe.com/pay/cs_123')

          expect(Stripe::Checkout::Session).to receive(:create).with({
            customer: 'cus_123',
            payment_method_types: [ 'card' ],
            line_items: [ {
              price: plan.stripe_price_id,
              quantity: 1
            } ],
            mode: 'subscription',
            success_url: success_url,
            cancel_url: cancel_url,
            metadata: {
              user_id: user.id,
              plan_id: plan.id
            },
            subscription_data: { trial_period_days: 14 }
          }).and_return(checkout_session)

          result = service.create_checkout_session(success_url: success_url, cancel_url: cancel_url)
          expect(result).to eq(checkout_session)
        end
      end

      it 'returns nil when customer creation fails' do
        allow_any_instance_of(StripeCustomerService).to receive(:find_or_create).and_return(nil)

        result = service.create_checkout_session(success_url: success_url, cancel_url: cancel_url)
        expect(result).to be_nil
      end

      it 'returns nil when Stripe API fails' do
        expect(Stripe::Checkout::Session).to receive(:create).and_raise(Stripe::StripeError.new('API error'))
        expect(Rails.logger).to receive(:error).with('Failed to create checkout session: API error')

        result = service.create_checkout_session(success_url: success_url, cancel_url: cancel_url)
        expect(result).to be_nil
      end
    end
  end

  describe '#create_subscription' do
    let(:stripe_subscription_id) { 'sub_123' }
    let(:stripe_subscription) do
      double('Stripe::Subscription',
        id: stripe_subscription_id,
        customer: 'cus_123',
        status: 'active',
        current_period_end: 1.month.from_now.to_i,
        cancel_at_period_end: false,
        items: double('items', data: [
          double('item', price: double('price', id: plan.stripe_price_id))
        ])
      )
    end

    before do
      allow(service).to receive(:retrieve_stripe_subscription).and_return(stripe_subscription)
    end

    context 'when stripe subscription cannot be retrieved' do
      before do
        allow(service).to receive(:retrieve_stripe_subscription).and_return(nil)
      end

      it 'returns nil' do
        expect(service.create_subscription(stripe_subscription_id)).to be_nil
      end
    end

    context 'when user has no existing subscription' do
      it 'creates a new subscription' do
        expect {
          result = service.create_subscription(stripe_subscription_id)
          expect(result).to be_a(Subscription)
          expect(result.stripe_subscription_id).to eq(stripe_subscription_id)
          expect(result.plan).to eq(plan)
          expect(result.status).to eq('active')
        }.to change(Subscription, :count).by(1)
      end
    end

    context 'when user has existing subscription' do
      let!(:existing_subscription) { create(:subscription, :with_stripe_ids, user: user) }

      it 'cancels existing subscription and creates new one' do
        expect(Stripe::Subscription).to receive(:cancel).with(existing_subscription.stripe_subscription_id)

        expect {
          result = service.create_subscription(stripe_subscription_id)
          expect(result).to be_a(Subscription)
          expect(result.id).not_to eq(existing_subscription.id)
        }.to change(Subscription, :count).by(0)

        expect(Subscription.find_by(id: existing_subscription.id)).to be_nil
      end

      it 'creates new subscription even if cancellation fails' do
        expect(Stripe::Subscription).to receive(:cancel).and_raise(Stripe::StripeError.new('Cancel failed'))

        result = service.create_subscription(stripe_subscription_id)
        expect(result).to be_a(Subscription)
      end
    end

    context 'when plan cannot be found' do
      let(:stripe_subscription) do
        double('Stripe::Subscription',
          id: stripe_subscription_id,
          customer: 'cus_123',
          status: 'active',
          current_period_end: 1.month.from_now.to_i,
          cancel_at_period_end: false,
          items: double('items', data: [
            double('item', price: double('price', id: 'price_unknown'))
          ])
        )
      end

      it 'returns nil' do
        expect(service.create_subscription(stripe_subscription_id)).to be_nil
      end
    end

    it 'handles ActiveRecord errors' do
      allow(user).to receive(:create_subscription!).and_raise(ActiveRecord::RecordInvalid.new(Subscription.new))
      expect(Rails.logger).to receive(:error).with(/Failed to create subscription record:/)

      expect(service.create_subscription(stripe_subscription_id)).to be_nil
    end
  end

  describe '#cancel_subscription' do
    context 'when user has no subscription' do
      it 'returns false' do
        expect(service.cancel_subscription).to be false
      end
    end

    context 'when subscription has no stripe_subscription_id' do
      let!(:subscription) { create(:subscription, user: user, stripe_subscription_id: nil) }

      it 'returns false' do
        expect(service.cancel_subscription).to be false
      end
    end

    context 'when subscription has stripe_subscription_id' do
      let!(:subscription) { create(:subscription, :with_stripe_ids, user: user) }

      context 'cancel at period end' do
        it 'updates Stripe subscription and local record' do
          expect(Stripe::Subscription).to receive(:update).with(
            subscription.stripe_subscription_id,
            cancel_at_period_end: true
          )

          expect(service.cancel_subscription(at_period_end: true)).to be true
          expect(subscription.reload.cancel_at_period_end).to be true
        end
      end

      context 'cancel immediately' do
        it 'cancels Stripe subscription and updates local record' do
          expect(Stripe::Subscription).to receive(:cancel).with(subscription.stripe_subscription_id)

          expect(service.cancel_subscription(at_period_end: false)).to be true
          expect(subscription.reload.status).to eq('canceled')
          expect(subscription.reload.cancel_at_period_end).to be false
        end
      end

      it 'returns false when Stripe API fails' do
        expect(Stripe::Subscription).to receive(:update).and_raise(Stripe::StripeError.new('API error'))
        expect(Rails.logger).to receive(:error).with('Failed to cancel subscription: API error')

        expect(service.cancel_subscription).to be false
      end
    end
  end

  describe '#sync_subscription_status' do
    context 'when user has no subscription' do
      it 'returns false' do
        expect(service.sync_subscription_status).to be false
      end
    end

    context 'when subscription has no stripe_subscription_id' do
      let!(:subscription) { create(:subscription, user: user, stripe_subscription_id: nil) }

      it 'returns false' do
        expect(service.sync_subscription_status).to be false
      end
    end

    context 'when subscription has stripe_subscription_id' do
      let!(:subscription) { create(:subscription, :with_stripe_ids, user: user) }
      let(:stripe_subscription) do
        double('Stripe::Subscription',
          status: 'past_due',
          current_period_end: 2.weeks.from_now.to_i,
          cancel_at_period_end: true
        )
      end

      before do
        allow(service).to receive(:retrieve_stripe_subscription).and_return(stripe_subscription)
      end

      it 'syncs status from Stripe' do
        expect(service.sync_subscription_status).to be true

        subscription.reload
        expect(subscription.status).to eq('past_due')
        expect(subscription.current_period_end).to be_between(13.days.from_now, 15.days.from_now)
        expect(subscription.cancel_at_period_end).to be true
      end

      it 'returns false when stripe subscription cannot be retrieved' do
        allow(service).to receive(:retrieve_stripe_subscription).and_return(nil)

        expect(service.sync_subscription_status).to be false
      end

      it 'returns false when Stripe API fails' do
        allow(service).to receive(:retrieve_stripe_subscription).and_raise(Stripe::StripeError.new('API error'))
        expect(Rails.logger).to receive(:error).with('Failed to sync subscription status: API error')

        expect(service.sync_subscription_status).to be false
      end
    end
  end

  describe 'private methods' do
    describe '#retrieve_stripe_subscription' do
      it 'retrieves subscription from Stripe' do
        stripe_subscription = double('Stripe::Subscription')
        expect(Stripe::Subscription).to receive(:retrieve).with('sub_123').and_return(stripe_subscription)

        result = service.send(:retrieve_stripe_subscription, 'sub_123')
        expect(result).to eq(stripe_subscription)
      end

      it 'returns nil and logs error on failure' do
        expect(Stripe::Subscription).to receive(:retrieve)
          .and_raise(Stripe::InvalidRequestError.new('Not found', 'subscription'))
        expect(Rails.logger).to receive(:error).with('Failed to retrieve subscription: Not found')

        result = service.send(:retrieve_stripe_subscription, 'sub_123')
        expect(result).to be_nil
      end
    end
  end
end
