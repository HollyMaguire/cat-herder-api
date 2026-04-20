FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email)    { |n| "user#{n}@example.com" }
    contact_type { "email" }
    password     { "password123" }
  end

  factory :phone_user, class: "User" do
    sequence(:username) { |n| "phoneuser#{n}" }
    sequence(:phone)    { |n| "+1555000#{n.to_s.rjust(4, '0')}" }
    contact_type { "phone" }
    password     { "password123" }
  end
end
