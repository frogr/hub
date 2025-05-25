class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    event = verify_and_construct_event
    process_webhook_event(event)
    render json: { received: true }, status: :ok
  rescue StripeSignatureVerificationService::InvalidPayloadError => e
    render json: { error: "Invalid payload" }, status: :bad_request
  rescue StripeSignatureVerificationService::InvalidSignatureError => e
    render json: { error: "Invalid signature" }, status: :bad_request
  end

  private

  def verify_and_construct_event
    StripeSignatureVerificationService.new(
      payload: request.body.read,
      signature_header: request.env["HTTP_STRIPE_SIGNATURE"]
    ).verify_and_construct_event
  end

  def process_webhook_event(event)
    StripeWebhookService.new(event).process
  end
end
