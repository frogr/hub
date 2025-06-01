# frozen_string_literal: true

module StripeDomain
  class Event
    attr_reader :id, :type, :data, :livemode, :created_at, :request_id

    SUBSCRIPTION_EVENTS = %w[
      customer.subscription.created
      customer.subscription.updated
      customer.subscription.deleted
      customer.subscription.trial_will_end
    ].freeze

    PAYMENT_EVENTS = %w[
      invoice.payment_succeeded
      invoice.payment_failed
      payment_intent.succeeded
      payment_intent.payment_failed
      checkout.session.completed
    ].freeze

    CUSTOMER_EVENTS = %w[
      customer.created
      customer.updated
      customer.deleted
    ].freeze

    def initialize(attributes = {})
      @id = attributes[:id]
      @type = attributes[:type]
      @data = attributes[:data]
      @livemode = attributes[:livemode]
      @created_at = attributes[:created_at]
      @request_id = attributes[:request_id]
    end

    def object
      return nil unless data
      data.is_a?(Hash) ? data["object"] || data[:object] : nil
    end

    def previous_attributes
      data["previous_attributes"] if data
    end

    def subscription?
      SUBSCRIPTION_EVENTS.include?(type)
    end

    def payment?
      PAYMENT_EVENTS.include?(type)
    end

    def customer?
      CUSTOMER_EVENTS.include?(type)
    end

    def subscription_created?
      type == "customer.subscription.created"
    end

    def subscription_updated?
      type == "customer.subscription.updated"
    end

    def subscription_deleted?
      type == "customer.subscription.deleted"
    end

    def payment_succeeded?
      type == "invoice.payment_succeeded"
    end

    def payment_failed?
      type == "invoice.payment_failed"
    end

    class << self
      def from_stripe(stripe_event)
        return nil unless stripe_event

        # Handle both real Stripe::Event objects and test doubles
        data = if stripe_event.respond_to?(:data)
          raw_data = stripe_event.data
          if raw_data.respond_to?(:to_h)
            raw_data.to_h
          elsif raw_data.is_a?(Hash)
            raw_data
          elsif raw_data.respond_to?(:[]) && raw_data.respond_to?(:object)
            # Handle Stripe::StripeObject
            { "object" => raw_data.object }
          else
            {}
          end
        else
          {}
        end

        new(
          id: stripe_event.respond_to?(:id) ? stripe_event.id : nil,
          type: stripe_event.type,
          data: data,
          livemode: stripe_event.respond_to?(:livemode) ? stripe_event.livemode : false,
          created_at: stripe_event.respond_to?(:created) ? Time.at(stripe_event.created).utc : Time.now.utc,
          request_id: stripe_event.respond_to?(:request) ? stripe_event.request&.id : nil
        )
      end

      def construct_from(payload, sig_header, endpoint_secret)
        stripe_event = ::Stripe::Webhook.construct_event(
          payload,
          sig_header,
          endpoint_secret
        )
        from_stripe(stripe_event)
      end
    end
  end
end
