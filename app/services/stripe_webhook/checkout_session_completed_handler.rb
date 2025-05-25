module StripeWebhook
  class CheckoutSessionCompletedHandler < BaseHandler
    def handle
      return unless event_object.mode == "subscription"

      user = User.find_by(id: event_object.metadata.user_id)
      return unless user

      SubscriptionService.new(user).create_subscription(event_object.subscription)
    end
  end
end
