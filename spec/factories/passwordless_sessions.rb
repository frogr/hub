FactoryBot.define do
  factory :passwordless_session do
    authenticatable_type { "MyString" }
    authenticatable_id { 1 }
    token { "MyString" }
    user_agent { "MyString" }
    remote_addr { "MyString" }
    expires_at { "2025-05-24 01:25:05" }
    timeout_at { "2025-05-24 01:25:05" }
    claimed_at { "2025-05-24 01:25:05" }
  end
end
