# frozen_string_literal: true

module StripeDomain
  class Customer
    attr_reader :id, :email, :name, :description, :metadata, :created_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @email = attributes[:email]
      @name = attributes[:name]
      @description = attributes[:description]
      @metadata = attributes[:metadata] || {}
      @created_at = attributes[:created_at]
    end

    def user_id
      metadata["user_id"]&.to_i
    end

    def to_stripe
      return nil unless id

      ::Stripe::Customer.retrieve(id)
    end

    class << self
      def from_stripe(stripe_customer)
        return nil unless stripe_customer

        new(
          id: stripe_customer.id,
          email: stripe_customer.email,
          name: stripe_customer.name,
          description: stripe_customer.description,
          metadata: stripe_customer.metadata.to_h,
          created_at: Time.at(stripe_customer.created).utc
        )
      end

      def find(id)
        stripe_customer = ::Stripe::Customer.retrieve(id)
        from_stripe(stripe_customer)
      rescue ::Stripe::InvalidRequestError
        nil
      end

      def find_or_create_for_user(user)
        return from_stripe(::Stripe::Customer.retrieve(user.stripe_customer_id)) if user.stripe_customer_id.present?

        stripe_customer = ::Stripe::Customer.create(
          email: user.email,
          metadata: { user_id: user.id }
        )

        user.update!(stripe_customer_id: stripe_customer.id)
        from_stripe(stripe_customer)
      end

      def update(id, attributes = {})
        stripe_customer = ::Stripe::Customer.update(id, attributes)
        from_stripe(stripe_customer)
      end
    end
  end
end
