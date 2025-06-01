# frozen_string_literal: true

module StripeDomain
  class WebhookHandler
    def initialize(event)
      @event = event
    end

    def handle
      return handle_subscription_event if @event.subscription?
      return handle_payment_event if @event.payment?
      return handle_customer_event if @event.customer?

      { handled: false, message: "Unhandled Stripe event type: #{@event.type}" }
    end

    private

    def handle_subscription_event
      case @event.type
      when "customer.subscription.created"
        handle_subscription_created
      when "customer.subscription.updated"
        handle_subscription_updated
      when "customer.subscription.deleted"
        handle_subscription_deleted
      when "customer.subscription.trial_will_end"
        handle_trial_will_end
      else
        { handled: false, message: "Unhandled subscription event: #{@event.type}" }
      end
    end

    def handle_payment_event
      case @event.type
      when "invoice.payment_succeeded"
        handle_payment_succeeded
      when "invoice.payment_failed"
        handle_payment_failed
      when "checkout.session.completed"
        handle_checkout_session_completed
      else
        { handled: false, message: "Unhandled payment event: #{@event.type}" }
      end
    end

    def handle_customer_event
      case @event.type
      when "customer.created"
        handle_customer_created
      when "customer.updated"
        handle_customer_updated
      when "customer.deleted"
        handle_customer_deleted
      else
        { handled: false, message: "Unhandled customer event: #{@event.type}" }
      end
    end

    def handle_subscription_created
      stripe_subscription = StripeDomain::Subscription.from_stripe(@event.object)
      return { handled: false, message: "Could not parse subscription" } unless stripe_subscription

      user = find_user_from_subscription(stripe_subscription)
      return { handled: false, message: "User not found" } unless user

      plan = find_plan_from_subscription(stripe_subscription)
      return { handled: false, message: "Plan not found" } unless plan

      subscription = ::Subscription.find_or_initialize_by(
        stripe_subscription_id: stripe_subscription.id
      )

      subscription.update!(
        user: user,
        plan: plan,
        status: stripe_subscription.status,
        current_period_end: stripe_subscription.current_period_end,
        trial_ends_at: stripe_subscription.trial_end,
        cancel_at_period_end: stripe_subscription.cancel_at_period_end
      )

      { handled: true, subscription: subscription }
    end

    def handle_subscription_updated
      stripe_subscription = StripeDomain::Subscription.from_stripe(@event.object)
      return { handled: false, message: "Could not parse subscription" } unless stripe_subscription

      subscription = ::Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return { handled: false, message: "Subscription not found" } unless subscription

      subscription.update!(
        status: stripe_subscription.status,
        current_period_end: stripe_subscription.current_period_end,
        trial_ends_at: stripe_subscription.trial_end,
        cancel_at_period_end: stripe_subscription.cancel_at_period_end
      )

      { handled: true, subscription: subscription }
    end

    def handle_subscription_deleted
      stripe_subscription = StripeDomain::Subscription.from_stripe(@event.object)
      return { handled: false, message: "Could not parse subscription" } unless stripe_subscription

      subscription = ::Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return { handled: false, message: "Subscription not found" } unless subscription

      subscription.update!(
        status: "canceled",
        cancel_at_period_end: false
      )

      { handled: true, subscription: subscription }
    end

    def handle_trial_will_end
      stripe_subscription = StripeDomain::Subscription.from_stripe(@event.object)
      return { handled: false, message: "Could not parse subscription" } unless stripe_subscription

      subscription = ::Subscription.find_by(stripe_subscription_id: stripe_subscription.id)
      return { handled: false, message: "Subscription not found" } unless subscription

      # Send trial ending email
      UserMailer.trial_ending(subscription.user).deliver_later

      { handled: true, subscription: subscription }
    end

    def handle_payment_succeeded
      invoice = @event.object
      return { handled: false, message: "No invoice object" } unless invoice

      subscription_id = if invoice.respond_to?(:[])
        invoice["subscription"] || invoice[:subscription]
      elsif invoice.respond_to?(:subscription)
        invoice.subscription
      end

      return { handled: false, message: "No subscription ID" } unless subscription_id

      subscription = ::Subscription.find_by(stripe_subscription_id: subscription_id)
      return { handled: false, message: "Subscription not found" } unless subscription

      subscription.update!(status: "active")
      { handled: true, subscription: subscription }
    end

    def handle_payment_failed
      invoice = @event.object
      return { handled: false, message: "No invoice object" } unless invoice

      subscription_id = if invoice.respond_to?(:[])
        invoice["subscription"] || invoice[:subscription]
      elsif invoice.respond_to?(:subscription)
        invoice.subscription
      end


      return { handled: false, message: "No subscription ID" } unless subscription_id

      subscription = ::Subscription.find_by(stripe_subscription_id: subscription_id)
      return { handled: false, message: "Subscription not found" } unless subscription

      subscription.update!(status: "past_due")

      # Log payment failure
      Rails.logger.warn "Payment failed for subscription #{subscription.id}"

      # Send payment failed email
      UserMailer.payment_failed(subscription.user).deliver_later

      { handled: true, subscription: subscription }
    end

    def handle_customer_created
      stripe_customer = StripeDomain::Customer.from_stripe(@event.object)
      return { handled: false, message: "Could not parse customer" } unless stripe_customer

      user = User.find_by(id: stripe_customer.user_id)
      return { handled: false, message: "User not found" } unless user

      user.update!(stripe_customer_id: stripe_customer.id)
      { handled: true, user: user }
    end

    def handle_customer_updated
      # Log for now, implement if needed
      { handled: true, message: "Customer updated" }
    end

    def handle_customer_deleted
      stripe_customer = StripeDomain::Customer.from_stripe(@event.object)
      return { handled: false, message: "Could not parse customer" } unless stripe_customer

      user = User.find_by(stripe_customer_id: stripe_customer.id)
      return { handled: false, message: "User not found" } unless user

      user.update!(stripe_customer_id: nil)
      { handled: true, user: user }
    end

    def handle_checkout_session_completed
      session = @event.object
      return { handled: false, message: "No session object" } unless session

      # Handle both Hash and Stripe::StripeObject
      mode = session.respond_to?(:[]) ? session["mode"] || session[:mode] : session.mode
      return { handled: false, message: "Not a subscription checkout" } unless mode == "subscription"

      subscription_id = session.respond_to?(:[]) ? session["subscription"] || session[:subscription] : session.subscription
      return { handled: false, message: "No subscription ID" } unless subscription_id

      # Access metadata
      metadata = if session.respond_to?(:[])
        session["metadata"] || session[:metadata]
      elsif session.respond_to?(:metadata)
        session.metadata
      end

      user_id = metadata&.respond_to?(:[]) ? metadata["user_id"] || metadata[:user_id] : metadata&.user_id
      return { handled: false, message: "No user_id in metadata" } unless user_id

      user = User.find_by(id: user_id)
      return { handled: false, message: "User not found" } unless user

      # Use SubscriptionService to create the subscription
      subscription_service = SubscriptionService.new(user)
      subscription = subscription_service.create_subscription(subscription_id)

      { handled: true, subscription: subscription }
    end

    private

    def find_user_from_subscription(stripe_subscription)
      return User.find_by(id: stripe_subscription.user_id) if stripe_subscription.user_id

      customer = StripeDomain::Customer.find(stripe_subscription.customer_id)
      return nil unless customer

      User.find_by(id: customer.user_id) || User.find_by(stripe_customer_id: customer.id)
    end

    def find_plan_from_subscription(stripe_subscription)
      return Plan.find_by(id: stripe_subscription.plan_id) if stripe_subscription.plan_id

      Plan.find_by(stripe_price_id: stripe_subscription.price_id)
    end
  end
end
