module StripeWebhook
  class BaseHandler
    attr_reader :event

    def initialize(event)
      @event = event
    end

    def handle
      raise NotImplementedError
    end

    private

    def event_object
      event.data.object
    end
  end
end
