FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "利用者#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
