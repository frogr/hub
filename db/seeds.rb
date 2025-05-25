# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create subscription plans
plans = [
  {
    name: "Free",
    amount: 0,
    currency: "usd",
    interval: "month",
    features: [
      "Basic features",
      "Limited access",
      "Community support"
    ],
    trial_days: 0
  },
  {
    name: "Pro",
    amount: 2900, # $29.00
    currency: "usd",
    interval: "month",
    features: [
      "All Free features",
      "Advanced features",
      "Priority support",
      "API access",
      "Custom integrations"
    ],
    trial_days: 7
  },
  {
    name: "Elite",
    amount: 9900, # $99.00
    currency: "usd",
    interval: "month",
    features: [
      "All Pro features",
      "Enterprise features",
      "Dedicated support",
      "Custom development",
      "SLA guarantee",
      "Advanced analytics"
    ],
    trial_days: 0
  }
]

plans.each do |plan_attrs|
  Plan.find_or_create_by!(name: plan_attrs[:name]) do |plan|
    plan.amount = plan_attrs[:amount]
    plan.currency = plan_attrs[:currency]
    plan.interval = plan_attrs[:interval]
    plan.features = plan_attrs[:features]
    plan.trial_days = plan_attrs[:trial_days]
  end
end

puts "Created #{Plan.count} subscription plans"
