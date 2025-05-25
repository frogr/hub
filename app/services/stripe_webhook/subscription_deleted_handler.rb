module StripeWebhook
  class SubscriptionDeletedHandler < BaseHandler
    def handle
      subscription = Subscription.find_by(stripe_subscription_id: event_object.id)
      return unless subscription

      subscription.update!(status: "canceled")
    end
  end
end
