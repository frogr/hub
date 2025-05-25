class StripeWebhookService
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def process
    handler_class = handler_for(event.type)
    return log_unhandled_event unless handler_class

    handler_class.new(event).handle
  rescue StandardError => e
    Rails.logger.error "Error handling Stripe webhook #{event.type}: #{e.message}"
    raise if Rails.env.test?
  end

  private

  def handler_for(event_type)
    case event_type
    when "checkout.session.completed"
      CheckoutSessionCompletedHandler
    when "customer.subscription.updated"
      SubscriptionUpdatedHandler
    when "customer.subscription.deleted"
      SubscriptionDeletedHandler
    when "invoice.payment_failed"
      PaymentFailedHandler
    end
  end

  def log_unhandled_event
    Rails.logger.info "Unhandled Stripe event type: #{event.type}"
  end

  class BaseHandler
    attr_reader :event

    def initialize(event)
      @event = event
    end

    def handle
      raise NotImplementedError
    end

    protected

    def event_object
      event.data.object
    end
  end

  class CheckoutSessionCompletedHandler < BaseHandler
    def handle
      return unless event_object.mode == "subscription"

      user = User.find_by(id: event_object.metadata.user_id)
      return unless user

      SubscriptionService.new(user).create_subscription(event_object.subscription)
    end
  end

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

  class SubscriptionDeletedHandler < BaseHandler
    def handle
      subscription = Subscription.find_by(stripe_subscription_id: event_object.id)
      return unless subscription

      subscription.update!(status: "canceled")
    end
  end

  class PaymentFailedHandler < BaseHandler
    def handle
      subscription = Subscription.find_by(stripe_subscription_id: event_object.subscription)
      return unless subscription

      Rails.logger.warn "Payment failed for subscription #{subscription.id}"
      # Future: send notification email to user
    end
  end
end
