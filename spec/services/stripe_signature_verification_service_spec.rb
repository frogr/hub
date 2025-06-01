require 'rails_helper'

RSpec.describe StripeSignatureVerificationService do
  let(:webhook_secret) { 'test_webhook_secret' }
  let(:payload) { { type: 'test.event', data: {} }.to_json }
  let(:timestamp) { Time.now.to_i }
  let(:signature) { generate_valid_signature(payload, timestamp, webhook_secret) }

  before do
    allow(Rails.configuration.stripe).to receive(:[]).with(:webhook_secret).and_return(webhook_secret)
  end

  def generate_valid_signature(payload, timestamp, secret)
    signed_payload = "#{timestamp}.#{payload}"
    signature = OpenSSL::HMAC.hexdigest('SHA256', secret, signed_payload)
    "t=#{timestamp},v1=#{signature}"
  end

  describe '#verify_and_construct_event' do
    subject(:service) do
      described_class.new(
        payload: payload,
        signature_header: signature
      )
    end

    context 'with valid signature' do
      it 'returns constructed Stripe event' do
        stripe_event = Stripe::Event.construct_from({ 
          id: 'evt_123',
          type: 'test.event',
          data: { object: { test: 'data' } },
          livemode: false,
          created: Time.now.to_i
        })

        expect(Stripe::Webhook).to receive(:construct_event)
          .with(payload, signature, webhook_secret)
          .and_return(stripe_event)

        result = service.verify_and_construct_event
        expect(result).to be_a(StripeDomain::Event)
        expect(result.type).to eq('test.event')
      end
    end

    context 'with custom webhook secret' do
      let(:custom_secret) { 'custom_webhook_secret' }
      let(:signature) { generate_valid_signature(payload, timestamp, custom_secret) }

      subject(:service) do
        described_class.new(
          payload: payload,
          signature_header: signature,
          webhook_secret: custom_secret
        )
      end

      it 'uses provided webhook secret' do
        expect(Stripe::Webhook).to receive(:construct_event)
          .with(payload, signature, custom_secret)
          .and_return(Stripe::Event.construct_from({ type: 'test.event' }))

        service.verify_and_construct_event
      end
    end

    context 'with invalid JSON payload' do
      it 'raises InvalidPayloadError' do
        allow(Stripe::Webhook).to receive(:construct_event)
          .and_raise(JSON::ParserError.new('Unexpected token'))

        expect { service.verify_and_construct_event }
          .to raise_error(
            StripeSignatureVerificationService::InvalidPayloadError,
            'Invalid JSON payload: Unexpected token'
          )
      end
    end

    context 'with invalid signature' do
      it 'raises InvalidSignatureError' do
        allow(Stripe::Webhook).to receive(:construct_event)
          .and_raise(Stripe::SignatureVerificationError.new('Invalid signature', signature))

        expect { service.verify_and_construct_event }
          .to raise_error(
            StripeSignatureVerificationService::InvalidSignatureError,
            'Invalid webhook signature: Invalid signature'
          )
      end
    end

    context 'with missing signature header' do
      let(:signature) { nil }

      it 'raises InvalidSignatureError' do
        allow(Stripe::Webhook).to receive(:construct_event)
          .and_raise(Stripe::SignatureVerificationError.new('No signature header', nil))

        expect { service.verify_and_construct_event }
          .to raise_error(StripeSignatureVerificationService::InvalidSignatureError)
      end
    end

    context 'with expired timestamp' do
      let(:old_timestamp) { 6.minutes.ago.to_i }
      let(:signature) { generate_valid_signature(payload, old_timestamp, webhook_secret) }

      it 'raises InvalidSignatureError' do
        allow(Stripe::Webhook).to receive(:construct_event)
          .and_raise(Stripe::SignatureVerificationError.new('Timestamp outside tolerance', signature))

        expect { service.verify_and_construct_event }
          .to raise_error(StripeSignatureVerificationService::InvalidSignatureError)
      end
    end
  end
end
