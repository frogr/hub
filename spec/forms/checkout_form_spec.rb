# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckoutForm do
  let(:user) { create(:user, stripe_customer_id: 'cus_123') }
  let(:plan) { create(:plan, stripe_price_id: 'price_123') }
  let(:form) do
    described_class.new(
      user_id: user.id,
      plan_id: plan.id,
      success_url: 'https://example.com/success',
      cancel_url: 'https://example.com/cancel'
    )
  end

  describe 'validations' do
    it 'requires user_id' do
      form.user_id = nil
      expect(form).not_to be_valid
      expect(form.errors[:user_id]).to include("can't be blank")
    end

    it 'requires plan_id' do
      form.plan_id = nil
      expect(form).not_to be_valid
      expect(form.errors[:plan_id]).to include("can't be blank")
    end

    it 'requires success_url' do
      form.success_url = nil
      expect(form).not_to be_valid
      expect(form.errors[:success_url]).to include("can't be blank")
    end

    it 'requires cancel_url' do
      form.cancel_url = nil
      expect(form).not_to be_valid
      expect(form.errors[:cancel_url]).to include("can't be blank")
    end

    it 'validates URL format' do
      form.success_url = 'not-a-url'
      form.cancel_url = 'also-not-a-url'
      expect(form).not_to be_valid
      expect(form.errors[:success_url]).to include('is invalid')
      expect(form.errors[:cancel_url]).to include('is invalid')
    end
  end

  describe '#user' do
    it 'returns the associated user' do
      expect(form.user).to eq(user)
    end
  end

  describe '#plan' do
    it 'returns the associated plan' do
      expect(form.plan).to eq(plan)
    end
  end

  describe '#create_checkout_session' do
    let(:stripe_session) do
      double('Stripe::Checkout::Session', id: 'cs_123', url: 'https://checkout.stripe.com/pay/cs_123')
    end

    before do
      allow(Stripe::Checkout::Session).to receive(:create).and_return(stripe_session)
    end

    context 'with valid attributes' do
      it 'creates a Stripe checkout session' do
        expect(form.create_checkout_session).to be true
        expect(form.stripe_session_id).to eq('cs_123')
      end

      it 'returns the checkout URL' do
        form.create_checkout_session
        expect(form.checkout_url).to eq('https://checkout.stripe.com/pay/cs_123')
      end

      context 'when user has no stripe_customer_id' do
        let(:user) { create(:user, stripe_customer_id: nil) }
        let(:stripe_customer) { double('Stripe::Customer', id: 'cus_new') }

        before do
          allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
        end

        it 'creates a Stripe customer first' do
          expect(Stripe::Customer).to receive(:create).with(
            email: user.email,
            metadata: { user_id: user.id }
          )
          form.create_checkout_session
        end

        it 'updates user with stripe_customer_id' do
          form.create_checkout_session
          expect(user.reload.stripe_customer_id).to eq('cus_new')
        end
      end
    end

    context 'with invalid attributes' do
      before do
        form.user_id = nil
      end

      it 'returns false without creating session' do
        expect(Stripe::Checkout::Session).not_to receive(:create)
        expect(form.create_checkout_session).to be false
      end
    end

    context 'when Stripe raises an error' do
      before do
        allow(Stripe::Checkout::Session).to receive(:create).and_raise(
          Stripe::InvalidRequestError.new('Invalid request', nil)
        )
      end

      it 'adds error and returns false' do
        expect(form.create_checkout_session).to be false
        expect(form.errors[:base]).to include('Invalid request')
      end
    end
  end

  describe '#save' do
    it 'delegates to create_checkout_session' do
      expect(form).to receive(:create_checkout_session).and_return(true)
      form.save
    end
  end
end