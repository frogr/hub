class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan

  validates :status, presence: true
  validates :stripe_subscription_id, uniqueness: true, allow_nil: true

  enum :status, {
    trialing: "trialing",
    active: "active",
    canceled: "canceled",
    past_due: "past_due",
    unpaid: "unpaid",
    incomplete: "incomplete"
  }

  scope :active_or_trialing, -> { where(status: [ :active, :trialing ]) }

  def active_or_trialing?
    if trialing? && trial_ends_at.present?
      trial_ends_at > Time.current && (active? || trialing?)
    else
      active? || trialing?
    end
  end

  def cancelled?
    canceled? || cancel_at_period_end?
  end

  def trial_expired?
    trialing? && trial_ends_at.present? && trial_ends_at <= Time.current
  end

  def days_remaining_in_trial
    return 0 unless trialing? && trial_ends_at.present?

    days = ((trial_ends_at - Time.current) / 1.day).ceil
    days.positive? ? days : 0
  end

  def cancel!
    return false unless stripe_subscription_id?

    stripe_subscription = Stripe::Subscription.update(
      stripe_subscription_id,
      cancel_at_period_end: true
    )
    
    update!(
      cancel_at_period_end: true,
      status: stripe_subscription.status
    )
    true
  rescue Stripe::StripeError
    false
  end
end
