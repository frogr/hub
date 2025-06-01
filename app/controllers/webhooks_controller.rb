class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    Webhook.process_stripe!(
      payload: request.body.read,
      signature: request.env["HTTP_STRIPE_SIGNATURE"]
    )
    render json: { received: true }, status: :ok
  rescue Stripe::SignatureVerificationError => e
    render json: { error: "Invalid signature" }, status: :bad_request
  rescue Stripe::StripeError => e
    render json: { error: e.message }, status: :bad_request
  end
end
