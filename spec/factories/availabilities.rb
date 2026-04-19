FactoryBot.define do
  factory :availability do
    association :user
    association :event
    slots { [] }
  end
end
