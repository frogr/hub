require_relative '../../lib/stripe_webhook_test_helper'

RSpec.configure do |config|
  config.include StripeWebhookTestHelper, type: :request
end

# Shared examples for webhook handlers
RSpec.shared_examples "webhook error handling" do
  it 'returns success even when handler raises error' do
    allow_any_instance_of(described_class).to receive(:handle).and_raise(StandardError.new('Handler error'))
    allow(Rails.logger).to receive(:error)

    expect { post_webhook(event_data) }.not_to raise_error
    expect(response).to have_http_status(:ok)
  end
end

RSpec.shared_examples "webhook signature validation" do
  it 'validates webhook signature' do
    post webhooks_stripe_path,
         params: payload,
         headers: { 'HTTP_STRIPE_SIGNATURE' => 'invalid_signature' }

    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)['error']).to eq('Invalid signature')
  end
end
