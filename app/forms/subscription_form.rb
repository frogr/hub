# frozen_string_literal: true

class SubscriptionForm < BaseForm
  attribute :user_id, :integer
  attribute :plan_id, :integer
  attribute :stripe_subscription_id, :string
  attribute :status, :string, default: "trialing"
  attribute :trial_ends_at, :datetime
  attribute :current_period_end, :datetime

  validates :user_id, presence: true
  validates :plan_id, presence: true
  validates :status, inclusion: { in: %w[trialing active canceled past_due] }

  def initialize(attributes = {})
    super
    @repository = SubscriptionRepository.new
  end

  def user
    @user ||= User.find_by(id: user_id)
  end

  def plan
    @plan ||= Plan.find_by(id: plan_id)
  end

  private

  def persist!
    subscription = @repository.create(
      user_id: user_id,
      plan_id: plan_id,
      stripe_subscription_id: stripe_subscription_id,
      status: status,
      trial_ends_at: trial_ends_at || 14.days.from_now,
      current_period_end: current_period_end
    )

    unless subscription.persisted?
      subscription.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
      raise ActiveRecord::RecordInvalid
    end

    @subscription = subscription
  end
end
