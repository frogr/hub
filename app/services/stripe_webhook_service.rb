class StripeWebhookService
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def process
    # Convert Stripe event to domain event
    domain_event = if event.is_a?(::Stripe::Event)
      ::StripeDomain::Event.from_stripe(event)
    elsif event.is_a?(::StripeDomain::Event)
      event
    else
      # Assume it's a hash and construct from it
      ::StripeDomain::Event.new(event)
    end

    # Use the new webhook handler
    handler = ::StripeDomain::WebhookHandler.new(domain_event)
    result = handler.handle

    unless result[:handled]
      Rails.logger.info result[:message] || "Unhandled Stripe event type: #{domain_event.type}"
    end

    result
  rescue StandardError => e
    Rails.logger.error "Error handling Stripe webhook #{domain_event.type}: #{e.message}"
    raise if Rails.env.test?
    { handled: false, error: e.message }
  end
end
