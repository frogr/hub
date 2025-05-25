class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, Rails.configuration.stripe[:webhook_secret]
      )
    rescue JSON::ParserError => e
      render json: { error: "Invalid payload" }, status: :bad_request and return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature" }, status: :bad_request and return
    end

    handle_stripe_event(event)
    render json: { received: true }, status: :ok
  end

  private

  def handle_stripe_event(event)
    case event.type
    when "checkout.session.completed"
      handle_checkout_session_completed(event)
    when "customer.subscription.updated"
      handle_subscription_updated(event)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event)
    when "invoice.payment_failed"
      handle_payment_failed(event)
    else
      Rails.logger.info "Unhandled Stripe event type: #{event.type}"
    end
  rescue StandardError => e
    Rails.logger.error "Error handling Stripe webhook: #{e.message}"
  end

  def handle_checkout_session_completed(event)
    session = event.data.object
    return unless session.mode == "subscription"

    user = User.find_by(id: session.metadata.user_id)
    return unless user

    service = SubscriptionService.new(user)
    service.create_subscription(session.subscription)
  end

  def handle_subscription_updated(event)
    subscription = event.data.object
    user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
    return unless user_subscription

    user_subscription.update!(
      status: subscription.status,
      current_period_end: Time.at(subscription.current_period_end),
      cancel_at_period_end: subscription.cancel_at_period_end
    )
  end

  def handle_subscription_deleted(event)
    subscription = event.data.object
    user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
    return unless user_subscription

    user_subscription.update!(status: "canceled")
  end

  def handle_payment_failed(event)
    invoice = event.data.object
    subscription = Subscription.find_by(stripe_subscription_id: invoice.subscription)
    return unless subscription

    Rails.logger.warn "Payment failed for subscription #{subscription.id}"
  end
end
