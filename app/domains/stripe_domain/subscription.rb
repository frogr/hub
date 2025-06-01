# frozen_string_literal: true

module StripeDomain
  class Subscription
    attr_reader :id, :customer_id, :status, :current_period_start, :current_period_end,
                :cancel_at_period_end, :canceled_at, :trial_start, :trial_end,
                :items, :metadata, :created_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @customer_id = attributes[:customer_id]
      @status = attributes[:status]
      @current_period_start = attributes[:current_period_start]
      @current_period_end = attributes[:current_period_end]
      @cancel_at_period_end = attributes[:cancel_at_period_end]
      @canceled_at = attributes[:canceled_at]
      @trial_start = attributes[:trial_start]
      @trial_end = attributes[:trial_end]
      @items = attributes[:items] || []
      @metadata = attributes[:metadata] || {}
      @created_at = attributes[:created_at]
    end

    def active?
      status == "active"
    end

    def trialing?
      status == "trialing"
    end

    def canceled?
      status == "canceled" || cancel_at_period_end
    end

    def past_due?
      status == "past_due"
    end

    def price_id
      items.first&.dig(:price, :id)
    end

    def user_id
      metadata["user_id"]&.to_i
    end

    def plan_id
      metadata["plan_id"]&.to_i
    end

    def to_stripe
      return nil unless id

      ::Stripe::Subscription.retrieve(id)
    end

    class << self
      def from_stripe(stripe_subscription)
        return nil unless stripe_subscription

        # Handle both real Stripe objects and test objects
        id = get_attribute(stripe_subscription, :id)
        customer = get_attribute(stripe_subscription, :customer)
        status = get_attribute(stripe_subscription, :status)
        current_period_start = get_attribute(stripe_subscription, :current_period_start)
        current_period_end = get_attribute(stripe_subscription, :current_period_end)
        cancel_at_period_end = get_attribute(stripe_subscription, :cancel_at_period_end)
        canceled_at = get_attribute(stripe_subscription, :canceled_at)
        trial_start = get_attribute(stripe_subscription, :trial_start)
        trial_end = get_attribute(stripe_subscription, :trial_end)
        created = get_attribute(stripe_subscription, :created)
        metadata = get_attribute(stripe_subscription, :metadata)

        new(
          id: id,
          customer_id: customer,
          status: status,
          current_period_start: current_period_start ? Time.at(current_period_start).utc : nil,
          current_period_end: current_period_end ? Time.at(current_period_end).utc : nil,
          cancel_at_period_end: cancel_at_period_end,
          canceled_at: canceled_at ? Time.at(canceled_at).utc : nil,
          trial_start: trial_start ? Time.at(trial_start).utc : nil,
          trial_end: trial_end ? Time.at(trial_end).utc : nil,
          items: parse_items(stripe_subscription),
          metadata: parse_metadata(metadata),
          created_at: created ? Time.at(created).utc : nil
        )
      end

      def find(id)
        stripe_subscription = ::Stripe::Subscription.retrieve(id)
        from_stripe(stripe_subscription)
      rescue ::Stripe::InvalidRequestError
        nil
      end

      def create(customer_id:, price_id:, metadata: {}, trial_period_days: nil)
        params = {
          customer: customer_id,
          items: [ { price: price_id } ],
          metadata: metadata
        }
        params[:trial_period_days] = trial_period_days if trial_period_days

        stripe_subscription = ::Stripe::Subscription.create(**params)
        from_stripe(stripe_subscription)
      end

      def cancel(id)
        stripe_subscription = ::Stripe::Subscription.update(
          id,
          cancel_at_period_end: true
        )
        from_stripe(stripe_subscription)
      end

      def cancel_immediately(id)
        stripe_subscription = ::Stripe::Subscription.cancel(id)
        from_stripe(stripe_subscription)
      end

      private

      def get_attribute(object, attribute)
        if object.respond_to?(attribute)
          object.send(attribute)
        elsif object.respond_to?(:[])
          object[attribute.to_s] || object[attribute]
        end
      end

      def parse_metadata(metadata)
        return {} unless metadata
        metadata.respond_to?(:to_h) ? metadata.to_h : metadata
      end

      def parse_items(stripe_subscription)
        items = get_attribute(stripe_subscription, :items)
        return [] unless items

        items_data = items.respond_to?(:data) ? items.data : items["data"] || []
        items_data.map { |item| safe_item_to_hash(item) }
      end

      def safe_item_to_hash(item)
        if item.is_a?(Hash)
          # Handle test data
          {
            id: item[:id] || item["id"],
            price: item[:price] || item["price"] || {},
            quantity: item[:quantity] || item["quantity"] || 1
          }
        elsif item.respond_to?(:[])
          # Handle Stripe::StripeObject from test data
          {
            id: item["id"],
            price: item["price"] || {},
            quantity: item["quantity"] || 1
          }
        else
          # Handle real Stripe objects with methods
          item_to_hash(item)
        end
      end

      def item_to_hash(item)
        {
          id: item.id,
          price: {
            id: item.price.id,
            product: item.price.product,
            unit_amount: item.price.unit_amount,
            currency: item.price.currency,
            recurring: item.price.recurring&.to_h
          },
          quantity: item.quantity
        }
      end
    end
  end
end
