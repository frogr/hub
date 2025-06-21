class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    event = Stripe::Webhook.construct_event(
      request.body.read,
      request.env["HTTP_STRIPE_SIGNATURE"],
      Rails.configuration.stripe[:webhook_secret]
    )

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event)
    when "customer.subscription.updated"
      handle_subscription_updated(event)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event)
    end

    render json: { received: true }, status: :ok
  rescue Stripe::SignatureVerificationError => e
    render json: { error: "Invalid signature" }, status: :bad_request
  rescue Stripe::StripeError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def handle_checkout_completed(event)
    return unless event.data.object.mode == "subscription"

    user = User.find(event.data.object.metadata.user_id)
    stripe_sub = Stripe::Subscription.retrieve(event.data.object.subscription)
    plan = Plan.find_by!(stripe_price_id: stripe_sub.items.data.first.price.id)

    user.subscriptions.active_or_trialing.destroy_all
    user.subscriptions.create!(
      plan: plan,
      stripe_subscription_id: event.data.object.subscription,
      status: stripe_sub.status,
      current_period_end: Time.at(stripe_sub.current_period_end),
      cancel_at_period_end: stripe_sub.cancel_at_period_end
    )
  end

  def handle_subscription_updated(event)
    subscription = Subscription.find_by!(stripe_subscription_id: event.data.object.id)
    subscription.update!(
      status: event.data.object.status,
      current_period_end: Time.at(event.data.object.current_period_end),
      cancel_at_period_end: event.data.object.cancel_at_period_end
    )
  end

  def handle_subscription_deleted(event)
    Subscription.find_by!(stripe_subscription_id: event.data.object.id)
                .update!(status: "canceled")
  end
end
