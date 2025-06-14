class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :passwordless_sessions, as: :authenticatable, dependent: :destroy
  has_one :subscription, dependent: :destroy

  after_create :create_trial_subscription

  def passwordless_with(user_agent:, remote_addr:)
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

  private

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
