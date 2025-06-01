# frozen_string_literal: true

class SubscriptionRepository
  def initialize(model_class = Subscription)
    @model_class = model_class
  end

  def find(id)
    @model_class.find_by(id: id)
  end

  def find_by_user(user)
    @model_class.where(user_id: user.id)
  end

  def active_for_user(user)
    @model_class
      .where(user_id: user.id, status: "active")
      .order(created_at: :desc)
      .first
  end

  def active_or_trialing_for_user(user)
    @model_class
      .where(user_id: user.id)
      .where(status: %w[active trialing])
      .order(created_at: :desc)
      .first
  end

  def all_for_user(user)
    @model_class
      .where(user_id: user.id)
      .includes(:plan)
      .order(created_at: :desc)
  end

  def create(attributes)
    @model_class.create(attributes)
  end

  def update(subscription, attributes)
    subscription.update(attributes)
    subscription
  end

  def cancel(subscription)
    subscription.update(
      status: "canceled",
      cancel_at_period_end: true
    )
  end

  def expired
    @model_class
      .where(status: %w[active trialing])
      .where("current_period_end < ?", Time.current)
  end

  def ending_trial_soon(days_before = 3)
    @model_class
      .where(status: "trialing")
      .where("trial_ends_at BETWEEN ? AND ?", Time.current, days_before.days.from_now)
  end

  def statistics
    {
      total: @model_class.count,
      active: @model_class.where(status: "active").count,
      trialing: @model_class.where(status: "trialing").count,
      cancelled: @model_class.where(status: "canceled").count,
      revenue: calculate_monthly_revenue
    }
  end

  private

  def calculate_monthly_revenue
    @model_class
      .joins(:plan)
      .where(status: "active")
      .sum("plans.amount") / 100.0
  end
end
