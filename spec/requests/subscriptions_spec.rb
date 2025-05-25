require 'rails_helper'

RSpec.describe 'Subscriptions', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET /subscriptions' do
    let!(:free_plan) { create(:plan, :free) }
    let!(:basic_plan) { create(:plan, name: 'Basic', amount: 999) }
    let!(:premium_plan) { create(:plan, name: 'Premium', amount: 1999) }

    it 'returns successful response' do
      get subscriptions_path
      expect(response).to have_http_status(:success)
    end

    it 'displays subscription management page' do
      get subscriptions_path

      expect(response.body).to include('Subscription Management')
      expect(response.body).to include('View Available Plans')
    end

    context 'when user has a subscription' do
      let!(:subscription) { create(:subscription, user: user, plan: basic_plan) }

      it 'shows current subscription' do
        get subscriptions_path
        expect(assigns(:current_subscription)).to eq(subscription)
      end
    end

    context 'when user has no subscription' do
      it 'shows no current subscription' do
        get subscriptions_path
        expect(assigns(:current_subscription)).to be_nil
      end
    end
  end

  describe 'GET /subscriptions/new' do
    context 'with valid plan_id' do
      let(:plan) { create(:plan, :with_stripe_price) }

      it 'returns successful response' do
        get new_subscription_path(plan_id: plan.id)
        expect(response).to have_http_status(:success)
      end

      it 'assigns the plan' do
        get new_subscription_path(plan_id: plan.id)
        expect(assigns(:plan)).to eq(plan)
      end
    end

    context 'without plan_id' do
      it 'redirects to subscriptions index' do
        get new_subscription_path
        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:alert]).to eq('Please select a plan')
      end
    end

    context 'with invalid plan_id' do
      it 'redirects to subscriptions index' do
        get new_subscription_path(plan_id: 999)
        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:alert]).to eq('Please select a plan')
      end
    end
  end

  describe 'POST /subscriptions' do
    let(:plan) { create(:plan, :with_stripe_price) }
    let(:checkout_session) { double('Stripe::Checkout::Session', url: 'https://checkout.stripe.com/pay/cs_123') }
    let(:subscription_service) { instance_double(SubscriptionService) }

    before do
      allow(SubscriptionService).to receive(:new).with(user, plan).and_return(subscription_service)
    end

    context 'with valid plan_id' do
      context 'when checkout session creation succeeds' do
        before do
          allow(subscription_service).to receive(:create_checkout_session).and_return(checkout_session)
        end

        it 'redirects to Stripe checkout' do
          post subscriptions_path(plan_id: plan.id)

          expect(response).to have_http_status(:see_other)
          expect(response).to redirect_to('https://checkout.stripe.com/pay/cs_123')
        end

        it 'passes correct URLs to service' do
          expect(subscription_service).to receive(:create_checkout_session).with(
            success_url: checkout_success_url(plan_id: plan.id),
            cancel_url: checkout_cancel_url
          ).and_return(checkout_session)

          post subscriptions_path(plan_id: plan.id)
        end
      end

      context 'when checkout session creation fails' do
        before do
          allow(subscription_service).to receive(:create_checkout_session).and_return(nil)
        end

        it 'redirects to subscriptions with error' do
          post subscriptions_path(plan_id: plan.id)

          expect(response).to redirect_to(subscriptions_path)
          expect(flash[:alert]).to eq('Unable to create checkout session. Please try again.')
        end
      end
    end

    context 'without plan_id' do
      before do
        allow(SubscriptionService).to receive(:new).with(user, nil).and_return(subscription_service)
      end

      it 'redirects to subscriptions index' do
        post subscriptions_path

        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:alert]).to eq('Please select a plan')
      end
    end
  end

  describe 'POST /subscriptions/:id/cancel' do
    let(:subscription_service) { instance_double(SubscriptionService) }
    let(:subscription) { create(:subscription, user: user) }

    before do
      allow(SubscriptionService).to receive(:new).with(user).and_return(subscription_service)
    end

    context 'when cancellation succeeds' do
      before do
        allow(subscription_service).to receive(:cancel_subscription).and_return(true)
      end

      it 'redirects with success message' do
        post cancel_subscription_path(subscription)

        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:notice]).to eq('Your subscription will be cancelled at the end of the billing period.')
      end
    end

    context 'when cancellation fails' do
      before do
        allow(subscription_service).to receive(:cancel_subscription).and_return(false)
      end

      it 'redirects with error message' do
        post cancel_subscription_path(subscription)

        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:alert]).to eq('Unable to cancel subscription. Please try again.')
      end
    end
  end

  describe 'authentication' do
    before do
      sign_out user
    end

    it 'requires authentication for index' do
      get subscriptions_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'requires authentication for new' do
      get new_subscription_path(plan_id: 1)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'requires authentication for create' do
      post subscriptions_path(plan_id: 1)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'requires authentication for cancel' do
      post cancel_subscription_path(1)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
