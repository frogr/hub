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
    active? || trialing?
  end

  def cancelled?
    canceled? || cancel_at_period_end?
  end
end
