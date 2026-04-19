FactoryBot.define do
  factory :invite do
    association :event
    sequence(:contact) { |n| "guest#{n}@example.com" }
    contact_type { "email" }
    status       { "pending" }
    is_vip       { false }
  end
end
