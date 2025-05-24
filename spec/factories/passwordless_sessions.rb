FactoryBot.define do
  factory :passwordless_session do
    association :authenticatable, factory: :user
    user_agent { "TestAgent/1.0" }
    remote_addr { "127.0.0.1" }
    expires_at { 1.hour.from_now }
    timeout_at { nil }
    claimed_at { nil }
  end
end
