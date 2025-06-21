require 'rails_helper'

RSpec.describe 'Webhooks', type: :request do
  describe 'POST /webhooks/stripe' do
    let(:webhook_secret) { 'test_webhook_secret' }
    let(:payload) { { type: 'test.event' }.to_json }
    let(:timestamp) { Time.now.to_i }
    let(:signature) { generate_stripe_signature(payload, timestamp, webhook_secret) }

    before do
      allow(Rails.configuration.stripe).to receive(:[]).with(:webhook_secret).and_return(webhook_secret)
    end

    def generate_stripe_signature(payload, timestamp, secret)
      signed_payload = "#{timestamp}.#{payload}"
      signature = OpenSSL::HMAC.hexdigest('SHA256', secret, signed_payload)
      "t=#{timestamp},v1=#{signature}"
    end

    def post_webhook(payload_data, headers = {})
      post webhooks_stripe_path,
           params: payload_data.to_json,
           headers: headers.merge({
             'Content-Type' => 'application/json',
             'HTTP_STRIPE_SIGNATURE' => signature
           })
    end

    context 'with valid signature' do
      it 'returns success' do
        event = double('event', type: 'test.event')
        expect(Stripe::Webhook).to receive(:construct_event).and_return(event)

        post_webhook({ type: 'test.event' })

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'received' => true })
      end
    end

    context 'with invalid signature' do
      it 'returns bad request' do
        expect(Stripe::Webhook).to receive(:construct_event)
          .and_raise(Stripe::SignatureVerificationError.new('Invalid signature', 'sig'))

        post_webhook({ type: 'test.event' })

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Invalid signature' })
      end
    end

    context 'with Stripe error' do
      it 'returns bad request' do
        expect(Stripe::Webhook).to receive(:construct_event)
          .and_raise(Stripe::StripeError.new('Something went wrong'))

        post_webhook({ type: 'test.event' })

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Something went wrong' })
      end
    end

    describe 'event handling' do
      let(:user) { create(:user) }
      let(:plan) { create(:plan, :with_stripe_price) }

      it 'processes checkout.session.completed events' do
        event_data = {
          id: 'evt_test',
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

        # Mock Stripe API calls
        stripe_subscription = double('subscription',
          items: double(data: [ double(price: double(id: plan.stripe_price_id)) ]),
          status: 'active',
          current_period_end: 1.month.from_now.to_i,
          cancel_at_period_end: false
        )

        event = Stripe::Event.construct_from(event_data)

        expect(Stripe::Webhook).to receive(:construct_event).and_return(event)
        expect(Stripe::Subscription).to receive(:retrieve).with('sub_123').and_return(stripe_subscription)

        expect {
          post_webhook(event_data)
        }.to change { user.subscriptions.count }.by(1)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
