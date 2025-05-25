FactoryBot.define do
  factory :subscription do
    association :user
    association :plan
    status { "active" }
    stripe_subscription_id { nil }
    stripe_customer_id { nil }
    current_period_end { 30.days.from_now }
    cancel_at_period_end { false }

    trait :trialing do
      status { "trialing" }
      current_period_end { 14.days.from_now }
    end

    trait :canceled do
      status { "canceled" }
      cancel_at_period_end { true }
    end

    trait :past_due do
      status { "past_due" }
    end

    trait :unpaid do
      status { "unpaid" }
    end

    trait :incomplete do
      status { "incomplete" }
    end

    trait :with_stripe_ids do
      sequence(:stripe_subscription_id) { |n| "sub_test_#{n}" }
      sequence(:stripe_customer_id) { |n| "cus_test_#{n}" }
    end
  end
end
