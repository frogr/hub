class StripeWebhookService
  attr_reader :event

  HANDLER_MAP = {
    "checkout.session.completed" => StripeWebhook::CheckoutSessionCompletedHandler,
    "customer.subscription.updated" => StripeWebhook::SubscriptionUpdatedHandler,
    "customer.subscription.deleted" => StripeWebhook::SubscriptionDeletedHandler,
    "invoice.payment_failed" => StripeWebhook::PaymentFailedHandler
  }.freeze

  def initialize(event)
    @event = event
  end

  def process
    handler_class = HANDLER_MAP[event.type]
    return log_unhandled_event unless handler_class

    handler_class.new(event).handle
  rescue StandardError => e
    Rails.logger.error "Error handling Stripe webhook #{event.type}: #{e.message}"
    raise if Rails.env.test?
  end

  private

  def log_unhandled_event
    Rails.logger.info "Unhandled Stripe event type: #{event.type}"
  end
end
