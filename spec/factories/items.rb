FactoryBot.define do
  factory :item do
    association :event
    association :added_by, factory: :user
    sequence(:name) { |n| "Item #{n}" }
  end
end
