FactoryBot.define do
  factory :plan do
    sequence(:name) { |n| "Plan #{n}" }
    amount { 1999 } # $19.99
    currency { "usd" }
    interval { "month" }
    features { ["Feature 1", "Feature 2", "Feature 3"] }
    trial_days { 0 }
    stripe_price_id { nil }

    trait :free do
      name { "Free Plan" }
      amount { 0 }
      features { ["Basic feature"] }
    end

    trait :yearly do
      interval { "year" }
      amount { 19999 } # $199.99
    end

    trait :with_trial do
      trial_days { 14 }
    end

    trait :with_stripe_price do
      sequence(:stripe_price_id) { |n| "price_test_#{n}" }
    end
  end
end