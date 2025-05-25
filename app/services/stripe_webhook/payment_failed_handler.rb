module StripeWebhook
  class PaymentFailedHandler < BaseHandler
    def handle
      subscription = Subscription.find_by(stripe_subscription_id: event_object.subscription)
      return unless subscription

      Rails.logger.warn "Payment failed for subscription #{subscription.id}"
      # Future: send notification email to user
    end
  end
end
