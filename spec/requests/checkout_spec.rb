require 'rails_helper'

RSpec.describe 'Checkout', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET /checkout/success' do
    context 'with valid plan_id' do
      let(:plan) { create(:plan) }

      it 'returns successful response' do
        get checkout_success_path(plan_id: plan.id)
        expect(response).to have_http_status(:success)
      end

      it 'assigns the plan' do
        get checkout_success_path(plan_id: plan.id)
        expect(assigns(:plan)).to eq(plan)
      end
    end

    context 'without plan_id' do
      it 'redirects to subscriptions with alert' do
        get checkout_success_path
        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:alert]).to eq('Invalid plan')
      end
    end

    context 'with invalid plan_id' do
      it 'redirects to subscriptions with alert' do
        get checkout_success_path(plan_id: 999)
        expect(response).to redirect_to(subscriptions_path)
        expect(flash[:alert]).to eq('Invalid plan')
      end
    end
  end

  describe 'GET /checkout/cancel' do
    it 'redirects to subscriptions with notice' do
      get checkout_cancel_path
      expect(response).to redirect_to(subscriptions_path)
      expect(flash[:notice]).to eq('Checkout was cancelled.')
    end
  end

  describe 'authentication' do
    before do
      sign_out user
    end

    it 'requires authentication for success' do
      get checkout_success_path(plan_id: 1)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'requires authentication for cancel' do
      get checkout_cancel_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
