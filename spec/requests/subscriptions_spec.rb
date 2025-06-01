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

    context 'with valid plan_id' do
      context 'when checkout session creation succeeds' do
        before do
          allow_any_instance_of(User).to receive(:create_checkout_session).and_return('https://checkout.stripe.com/pay/cs_123')
        end

        it 'redirects to Stripe checkout' do
          post subscriptions_path(plan_id: plan.id)

          expect(response).to have_http_status(:see_other)
          expect(response).to redirect_to('https://checkout.stripe.com/pay/cs_123')
        end
      end

      context 'when checkout session creation fails' do
        before do
          allow_any_instance_of(User).to receive(:create_checkout_session).and_raise(Stripe::StripeError.new('Payment failed'))
        end

        it 'redirects with error' do
          post subscriptions_path(plan_id: plan.id)

          expect(response).to redirect_to(subscriptions_path)
          expect(flash[:alert]).to eq('Payment failed')
        end
      end
    end

    context 'without plan_id' do
      it 'redirects to subscriptions index' do
        post subscriptions_path

        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:alert]).to include('Please select a plan')
      end
    end
  end

  describe 'POST /subscriptions/:id/cancel' do
    let(:subscription) { create(:subscription, user: user, status: 'active', stripe_subscription_id: 'sub_123') }

    before do
      user.subscriptions << subscription
    end

    context 'when cancellation succeeds' do
      before do
        allow_any_instance_of(Subscription).to receive(:cancel!).and_return(true)
      end

      it 'redirects with success message' do
        post cancel_subscription_path(subscription)

        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:notice]).to eq('Your subscription will be cancelled at the end of the billing period.')
      end
    end

    context 'when cancellation fails' do
      before do
        allow_any_instance_of(Subscription).to receive(:cancel!).and_return(false)
      end

      it 'redirects with error message' do
        post cancel_subscription_path(subscription)

        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:alert]).to eq('Unable to cancel subscription.')
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
