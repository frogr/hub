require 'rails_helper'

RSpec.describe Webhook, type: :model do
  describe '.process_stripe!' do
    let(:payload) { { type: 'test.event' }.to_json }
    let(:signature) { 'test_signature' }
    let(:event) { Stripe::Event.construct_from(JSON.parse(payload)) }

    before do
      allow(Rails.configuration.stripe).to receive(:[]).with(:webhook_secret).and_return('test_secret')
      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
    end

    context 'with checkout.session.completed event' do
      let(:user) { create(:user) }
      let(:event_data) do
        {
          id: 'evt_123',
          type: 'checkout.session.completed',
          data: {
            object: {
              mode: 'subscription',
              subscription: 'sub_123',
              metadata: { user_id: user.id.to_s }
            }
          }
        }
      end
      let(:event) { Stripe::Event.construct_from(event_data) }

      it 'processes the checkout completion' do
        expect_any_instance_of(User).to receive(:process_checkout_completed).with('sub_123')
        
        described_class.process_stripe!(payload: event_data.to_json, signature: signature)
        
        webhook = Webhook.last
        expect(webhook.event_type).to eq('checkout.session.completed')
        expect(webhook.event_id).to eq('evt_123')
        expect(webhook.processed_at).to be_present
      end
    end

    context 'with customer.subscription.updated event' do
      let(:subscription) { create(:subscription, stripe_subscription_id: 'sub_123') }
      let(:event_data) do
        {
          id: 'evt_456',
          type: 'customer.subscription.updated',
          data: {
            object: {
              id: 'sub_123',
              status: 'active',
              current_period_end: 1.month.from_now.to_i,
              cancel_at_period_end: false
            }
          }
        }
      end
      let(:event) { Stripe::Event.construct_from(event_data) }

      it 'updates the subscription' do
        described_class.process_stripe!(payload: event_data.to_json, signature: signature)
        
        subscription.reload
        expect(subscription.status).to eq('active')
        expect(subscription.cancel_at_period_end).to be false
        
        webhook = Webhook.last
        expect(webhook.event_type).to eq('customer.subscription.updated')
      end
    end

    context 'with customer.subscription.deleted event' do
      let(:subscription) { create(:subscription, stripe_subscription_id: 'sub_789', status: 'active') }
      let(:event_data) do
        {
          id: 'evt_789',
          type: 'customer.subscription.deleted',
          data: {
            object: {
              id: 'sub_789'
            }
          }
        }
      end
      let(:event) { Stripe::Event.construct_from(event_data) }

      it 'cancels the subscription' do
        described_class.process_stripe!(payload: event_data.to_json, signature: signature)
        
        subscription.reload
        expect(subscription.status).to eq('canceled')
        
        webhook = Webhook.last
        expect(webhook.event_type).to eq('customer.subscription.deleted')
      end
    end
  end
end