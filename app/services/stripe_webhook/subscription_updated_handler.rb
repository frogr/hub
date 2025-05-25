module StripeWebhook
  class SubscriptionUpdatedHandler < BaseHandler
    def handle
      subscription = Subscription.find_by(stripe_subscription_id: event_object.id)
      return unless subscription

      subscription.update!(
        status: event_object.status,
        current_period_end: Time.at(event_object.current_period_end),
        cancel_at_period_end: event_object.cancel_at_period_end
      )
    end
  end
end
