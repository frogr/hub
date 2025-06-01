class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :passwordless_sessions, as: :authenticatable, dependent: :destroy
  has_one :subscription, -> { where(status: [:active, :trialing]) }, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  after_create :create_trial_subscription

  def passwordless_with(user_agent:, remote_addr:)
    passwordless_sessions.create!(
      user_agent: user_agent,
      remote_addr: remote_addr,
      expires_at: passwordless_session_duration.from_now
    )
  end

  def create_passwordless_session!(user_agent: nil, remote_addr: nil)
    passwordless_sessions.create!(
      user_agent: user_agent,
      remote_addr: remote_addr,
      expires_at: passwordless_session_duration.from_now
    )
  end

  def passwordless_login_enabled?
    true # Default to enabled for all users. Can be made configurable later.
  end

  def can_authenticate_with_password?
    encrypted_password.present?
  end

  def authentication_method
    if passwordless_login_enabled?
      :passwordless
    elsif can_authenticate_with_password?
      :password
    else
      :none
    end
  end

  def has_active_subscription?
    subscription&.active_or_trialing?
  end

  def subscribed_to?(plan)
    subscription&.plan == plan && has_active_subscription?
  end

  def current_plan
    subscription&.plan
  end

  def stripe_customer
    StripeCustomerService.new(self).find_or_create
  end

  def create_or_update_stripe_customer
    StripeCustomerService.new(self).find_or_create
  end

  def create_checkout_session(plan:, success_url:, cancel_url:)
    ensure_stripe_customer!
    
    Stripe::Checkout::Session.create(
      customer: stripe_customer_id,
      payment_method_types: ['card'],
      line_items: [{ price: plan.stripe_price_id, quantity: 1 }],
      mode: 'subscription',
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: { user_id: id, plan_id: plan.id },
      subscription_data: plan.trial_days? ? { trial_period_days: plan.trial_days } : {}
    ).url
  end

  def process_checkout_completed(stripe_subscription_id)
    stripe_sub = Stripe::Subscription.retrieve(stripe_subscription_id)
    plan = Plan.find_by!(stripe_price_id: stripe_sub.items.data.first.price.id)
    
    subscriptions.active_or_trialing.destroy_all # Cancel existing
    
    subscriptions.create!(
      plan: plan,
      stripe_subscription_id: stripe_subscription_id,
      stripe_customer_id: stripe_sub.customer,
      status: stripe_sub.status,
      current_period_end: Time.at(stripe_sub.current_period_end),
      cancel_at_period_end: stripe_sub.cancel_at_period_end
    )
  end

  def recent_sessions(limit: 10)
    passwordless_sessions
      .order(created_at: :desc)
      .limit(limit)
  end

  private

  def ensure_stripe_customer!
    return if stripe_customer_id?

    customer = Stripe::Customer.create(
      email: email,
      metadata: { user_id: id, environment: Rails.env }
    )
    update!(stripe_customer_id: customer.id)
  end

  def passwordless_session_duration
    1.hour
  end

  def create_trial_subscription
    return if Rails.env.test? # Skip in test environment to avoid plan dependency

    pro_plan = Plan.find_by(name: "Pro")
    return unless pro_plan && pro_plan.trial_days > 0

    create_subscription!(
      plan: pro_plan,
      status: "trialing",
      trial_ends_at: pro_plan.trial_days.days.from_now,
      current_period_end: pro_plan.trial_days.days.from_now
    )
  end
end
