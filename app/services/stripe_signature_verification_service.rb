class StripeSignatureVerificationService
  attr_reader :payload, :signature_header, :webhook_secret

  def initialize(payload:, signature_header:, webhook_secret: nil)
    @payload = payload
    @signature_header = signature_header
    @webhook_secret = webhook_secret || Rails.configuration.stripe[:webhook_secret]
  end

  def verify_and_construct_event
    ::StripeDomain::Event.construct_from(payload, signature_header, webhook_secret)
  rescue JSON::ParserError => e
    raise InvalidPayloadError, "Invalid JSON payload: #{e.message}"
  rescue ::Stripe::SignatureVerificationError => e
    raise InvalidSignatureError, "Invalid webhook signature: #{e.message}"
  end

  class InvalidPayloadError < StandardError; end
  class InvalidSignatureError < StandardError; end
end
