class Plan < ApplicationRecord
  has_many :subscriptions

  validates :name, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :interval, presence: true, inclusion: { in: %w[month year] }
  validates :stripe_price_id, uniqueness: true, allow_nil: true
  validates :trial_days, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  serialize :features, type: Array, coder: JSON

  def free?
    amount == 0
  end

  def display_price
    if free?
      "Free"
    else
      "$#{amount / 100.0}/#{interval}"
    end
  end
end
