require 'rails_helper'

RSpec.describe StripeCustomerService, type: :service do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }
  
  describe '#initialize' do
    it 'sets the user' do
      expect(service.user).to eq(user)
    end
  end

  describe '#find_or_create' do
    context 'when user has no stripe_customer_id' do
      before do
        user.update!(stripe_customer_id: nil)
      end

      it 'creates a new Stripe customer' do
        stripe_customer = double('Stripe::Customer', id: 'cus_new123')
        
        expect(Stripe::Customer).to receive(:create).with({
          email: user.email,
          metadata: {
            user_id: user.id,
            environment: Rails.env
          }
        }).and_return(stripe_customer)

        result = service.find_or_create
        
        expect(result).to eq(stripe_customer)
        expect(user.reload.stripe_customer_id).to eq('cus_new123')
      end

      it 'returns nil when Stripe API fails' do
        expect(Stripe::Customer).to receive(:create).and_raise(Stripe::StripeError.new('API error'))
        
        expect(Rails.logger).to receive(:error).with('Failed to create Stripe customer: API error')
        
        result = service.find_or_create
        expect(result).to be_nil
        expect(user.reload.stripe_customer_id).to be_nil
      end
    end

    context 'when user has existing stripe_customer_id' do
      before do
        user.update!(stripe_customer_id: 'cus_existing123')
      end

      it 'retrieves the existing Stripe customer' do
        stripe_customer = double('Stripe::Customer', id: 'cus_existing123')
        
        expect(Stripe::Customer).to receive(:retrieve).with('cus_existing123').and_return(stripe_customer)
        expect(Stripe::Customer).not_to receive(:create)

        result = service.find_or_create
        expect(result).to eq(stripe_customer)
      end

      it 'creates new customer when existing customer cannot be retrieved' do
        new_customer = double('Stripe::Customer', id: 'cus_new123')
        
        expect(Stripe::Customer).to receive(:retrieve).with('cus_existing123')
          .and_raise(Stripe::InvalidRequestError.new('Customer not found', 'customer'))
        
        expect(Rails.logger).to receive(:error).with('Failed to retrieve Stripe customer: Customer not found')
        
        expect(Stripe::Customer).to receive(:create).with({
          email: user.email,
          metadata: {
            user_id: user.id,
            environment: Rails.env
          }
        }).and_return(new_customer)

        result = service.find_or_create
        expect(result).to eq(new_customer)
        expect(user.reload.stripe_customer_id).to eq('cus_new123')
      end
    end
  end

  describe '#update' do
    context 'when user has no stripe_customer_id' do
      before do
        user.update!(stripe_customer_id: nil)
      end

      it 'returns nil' do
        expect(Stripe::Customer).not_to receive(:update)
        expect(service.update).to be_nil
      end
    end

    context 'when user has stripe_customer_id' do
      before do
        user.update!(stripe_customer_id: 'cus_123')
      end

      it 'updates the Stripe customer' do
        updated_customer = double('Stripe::Customer')
        
        expect(Stripe::Customer).to receive(:update).with(
          'cus_123',
          {
            email: user.email,
            metadata: {
              user_id: user.id,
              environment: Rails.env
            }
          }
        ).and_return(updated_customer)

        result = service.update
        expect(result).to eq(updated_customer)
      end

      it 'returns nil when update fails' do
        expect(Stripe::Customer).to receive(:update)
          .and_raise(Stripe::InvalidRequestError.new('Invalid request', 'request'))
        
        expect(Rails.logger).to receive(:error).with('Failed to update Stripe customer: Invalid request')
        
        result = service.update
        expect(result).to be_nil
      end
    end
  end

  describe '#sync_from_stripe' do
    context 'when user has no stripe_customer_id' do
      before do
        user.update!(stripe_customer_id: nil)
      end

      it 'returns nil' do
        expect(Stripe::Customer).not_to receive(:retrieve)
        expect(service.sync_from_stripe).to be_nil
      end
    end

    context 'when user has stripe_customer_id' do
      before do
        user.update!(stripe_customer_id: 'cus_123', email: 'old@example.com')
      end

      it 'syncs email from Stripe when different' do
        stripe_customer = double('Stripe::Customer', 
          id: 'cus_123',
          email: 'new@example.com'
        )
        
        expect(Stripe::Customer).to receive(:retrieve).with('cus_123').and_return(stripe_customer)

        result = service.sync_from_stripe
        
        expect(result).to eq(stripe_customer)
        expect(user.reload.email).to eq('new@example.com')
      end

      it 'does not update email when same' do
        stripe_customer = double('Stripe::Customer', 
          id: 'cus_123',
          email: 'old@example.com'
        )
        
        expect(Stripe::Customer).to receive(:retrieve).with('cus_123').and_return(stripe_customer)

        result = service.sync_from_stripe
        
        expect(result).to eq(stripe_customer)
        expect(user).not_to receive(:update!)
      end

      it 'returns nil when customer cannot be retrieved' do
        expect(Stripe::Customer).to receive(:retrieve)
          .and_raise(Stripe::InvalidRequestError.new('Not found', 'customer'))
        
        expect(Rails.logger).to receive(:error).with('Failed to retrieve Stripe customer: Not found')
        
        result = service.sync_from_stripe
        expect(result).to be_nil
      end
    end
  end

  describe 'private methods' do
    describe '#customer_attributes' do
      it 'returns correct attributes hash' do
        attributes = service.send(:customer_attributes)
        
        expect(attributes).to eq({
          email: user.email,
          metadata: {
            user_id: user.id,
            environment: Rails.env
          }
        })
      end
    end
  end
end