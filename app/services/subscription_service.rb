class SubscriptionService
  attr_reader :user, :plan

  def initialize(user, plan = nil)
    @user = user
    @plan = plan
  end

  def create_checkout_session(success_url:, cancel_url:)
    return nil unless plan && plan.stripe_price_id.present?

    customer = ensure_stripe_customer
    return nil unless customer

    session_params = {
      customer: customer.id,
      payment_method_types: [ "card" ],
      line_items: [ {
        price: plan.stripe_price_id,
        quantity: 1
      } ],
      mode: "subscription",
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: {
        user_id: user.id,
        plan_id: plan.id
      }
    }

    session_params[:subscription_data] = { trial_period_days: plan.trial_days } if plan.trial_days > 0

    Stripe::Checkout::Session.create(session_params)
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to create checkout session: #{e.message}"
    nil
  end

  def create_subscription(stripe_subscription_id)
    stripe_subscription = retrieve_stripe_subscription(stripe_subscription_id)
    return nil unless stripe_subscription

    ActiveRecord::Base.transaction do
      cancel_existing_subscription
      create_new_subscription(stripe_subscription)
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create subscription record: #{e.message}"
    nil
  end

  def cancel_subscription(at_period_end: true)
    subscription = user.subscription
    return false unless subscription&.stripe_subscription_id.present?

    if at_period_end
      Stripe::Subscription.update(
        subscription.stripe_subscription_id,
        cancel_at_period_end: true
      )
      subscription.update!(cancel_at_period_end: true)
    else
      Stripe::Subscription.cancel(subscription.stripe_subscription_id)
      subscription.update!(status: "canceled", cancel_at_period_end: false)
    end

    true
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to cancel subscription: #{e.message}"
    false
  end

  def sync_subscription_status
    subscription = user.subscription
    return false unless subscription&.stripe_subscription_id.present?

    stripe_subscription = retrieve_stripe_subscription(subscription.stripe_subscription_id)
    return false unless stripe_subscription

    subscription.update!(
      status: stripe_subscription.status,
      current_period_end: Time.at(stripe_subscription.current_period_end),
      cancel_at_period_end: stripe_subscription.cancel_at_period_end
    )

    true
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to sync subscription status: #{e.message}"
    false
  end

  private

  def ensure_stripe_customer
    StripeCustomerService.new(user).find_or_create
  end

  def retrieve_stripe_subscription(subscription_id)
    Stripe::Subscription.retrieve(subscription_id)
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error "Failed to retrieve subscription: #{e.message}"
    nil
  end

  def cancel_existing_subscription
    existing = user.subscription
    return unless existing

    if existing.stripe_subscription_id.present?
      Stripe::Subscription.cancel(existing.stripe_subscription_id) rescue nil
    end
    existing.destroy!
  end

  def create_new_subscription(stripe_subscription)
    plan = Plan.find_by(stripe_price_id: stripe_subscription.items.data.first.price.id)
    return nil unless plan

    user.create_subscription!(
      plan: plan,
      stripe_subscription_id: stripe_subscription.id,
      stripe_customer_id: stripe_subscription.customer,
      status: stripe_subscription.status,
      current_period_end: Time.at(stripe_subscription.current_period_end),
      cancel_at_period_end: stripe_subscription.cancel_at_period_end
    )
  end
end
