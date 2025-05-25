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
        expect_any_instance_of(StripeSignatureVerificationService)
          .to receive(:verify_and_construct_event)
          .and_return(Stripe::Event.construct_from({ type: 'test.event' }))

        expect_any_instance_of(StripeWebhookService).to receive(:process)

        post_webhook({ type: 'test.event' })

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ 'received' => true })
      end
    end

    context 'with invalid JSON payload' do
      it 'returns bad request' do
        allow_any_instance_of(StripeSignatureVerificationService)
          .to receive(:verify_and_construct_event)
          .and_raise(StripeSignatureVerificationService::InvalidPayloadError.new('Invalid JSON payload'))

        post webhooks_stripe_path,
             params: 'invalid json',
             headers: { 'HTTP_STRIPE_SIGNATURE' => signature }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Invalid payload' })
      end
    end

    context 'with invalid signature' do
      it 'returns bad request' do
        allow_any_instance_of(StripeSignatureVerificationService)
          .to receive(:verify_and_construct_event)
          .and_raise(StripeSignatureVerificationService::InvalidSignatureError.new('Invalid webhook signature'))

        post_webhook({ type: 'test.event' })

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Invalid signature' })
      end
    end

    describe 'event handling' do
      let(:user) { create(:user) }
      let(:plan) { create(:plan, :with_stripe_price) }

      before do
        allow_any_instance_of(StripeSignatureVerificationService)
          .to receive(:verify_and_construct_event)
          .and_return(event)
      end

      describe 'checkout.session.completed' do
        let(:event) do
          Stripe::Event.construct_from({
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
          })
        end

        it 'creates subscription through service' do
          subscription_service = instance_double(SubscriptionService)
          expect(SubscriptionService).to receive(:new).with(user).and_return(subscription_service)
          expect(subscription_service).to receive(:create_subscription).with('sub_123')

          post_webhook({ type: 'checkout.session.completed' })
          expect(response).to have_http_status(:ok)
        end

        it 'ignores non-subscription mode sessions' do
          event.data.object.mode = 'payment'
          expect(SubscriptionService).not_to receive(:new)

          post_webhook({ type: 'checkout.session.completed' })
          expect(response).to have_http_status(:ok)
        end

        it 'handles missing user gracefully' do
          event.data.object.metadata.user_id = '999999'
          expect(SubscriptionService).not_to receive(:new)

          post_webhook({ type: 'checkout.session.completed' })
          expect(response).to have_http_status(:ok)
        end
      end

      describe 'customer.subscription.updated' do
        let(:subscription) { create(:subscription, :with_stripe_ids, user: user) }
        let(:event) do
          Stripe::Event.construct_from({
            type: 'customer.subscription.updated',
            data: {
              object: {
                id: subscription.stripe_subscription_id,
                status: 'past_due',
                current_period_end: 2.weeks.from_now.to_i,
                cancel_at_period_end: true
              }
            }
          })
        end

        it 'updates subscription status' do
          post_webhook({ type: 'customer.subscription.updated' })

          expect(response).to have_http_status(:ok)
          subscription.reload
          expect(subscription.status).to eq('past_due')
          expect(subscription.cancel_at_period_end).to be true
          expect(subscription.current_period_end).to be_between(13.days.from_now, 15.days.from_now)
        end

        it 'handles missing subscription gracefully' do
          nonexistent_event = {
            type: 'customer.subscription.updated',
            data: {
              object: {
                id: 'sub_nonexistent',
                status: 'active',
                current_period_end: Time.now.to_i + 30.days,
                cancel_at_period_end: false
              }
            }
          }

          expect {
            post_webhook(nonexistent_event)
          }.not_to raise_error

          expect(response).to have_http_status(:ok)
        end
      end

      describe 'customer.subscription.deleted' do
        let(:subscription) { create(:subscription, :with_stripe_ids, user: user) }
        let(:event) do
          Stripe::Event.construct_from({
            type: 'customer.subscription.deleted',
            data: {
              object: {
                id: subscription.stripe_subscription_id
              }
            }
          })
        end

        it 'marks subscription as canceled' do
          post_webhook({ type: 'customer.subscription.deleted' })

          expect(response).to have_http_status(:ok)
          expect(subscription.reload.status).to eq('canceled')
        end

        it 'handles missing subscription gracefully' do
          nonexistent_event = {
            type: 'customer.subscription.deleted',
            data: {
              object: {
                id: 'sub_nonexistent'
              }
            }
          }

          expect {
            post_webhook(nonexistent_event)
          }.not_to raise_error

          expect(response).to have_http_status(:ok)
        end
      end

      describe 'invoice.payment_failed' do
        let(:subscription) { create(:subscription, :with_stripe_ids, user: user) }
        let(:event) do
          Stripe::Event.construct_from({
            type: 'invoice.payment_failed',
            data: {
              object: {
                subscription: subscription.stripe_subscription_id
              }
            }
          })
        end

        it 'logs payment failure' do
          expect(Rails.logger).to receive(:warn).with("Payment failed for subscription #{subscription.id}")

          post_webhook({ type: 'invoice.payment_failed' })
          expect(response).to have_http_status(:ok)
        end

        it 'handles missing subscription gracefully' do
          event.data.object.subscription = 'sub_nonexistent'

          expect(Rails.logger).not_to receive(:warn)

          post_webhook({ type: 'invoice.payment_failed' })
          expect(response).to have_http_status(:ok)
        end
      end

      describe 'unhandled event types' do
        let(:event) do
          Stripe::Event.construct_from({
            type: 'unhandled.event.type',
            data: { object: {} }
          })
        end

        it 'logs unhandled event and returns success' do
          allow(Rails.logger).to receive(:info)

          post_webhook({ type: 'unhandled.event.type' })

          expect(response).to have_http_status(:ok)
          expect(Rails.logger).to have_received(:info).with('Unhandled Stripe event type: unhandled.event.type')
        end
      end

      describe 'error handling' do
        let(:event) do
          Stripe::Event.construct_from({
            type: 'checkout.session.completed',
            data: {
              object: {
                mode: 'subscription',
                subscription: 'sub_123',
                metadata: { user_id: user.id.to_s }
              }
            }
          })
        end

        it 'catches and logs errors without failing the request' do
          # In test environment, errors are re-raised by design, so we need to allow that
          allow(Rails.env).to receive(:test?).and_return(false)
          allow(User).to receive(:find_by).and_raise(StandardError.new('Database error'))
          expect(Rails.logger).to receive(:error).with('Error handling Stripe webhook checkout.session.completed: Database error')

          post_webhook({ type: 'checkout.session.completed' })
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
