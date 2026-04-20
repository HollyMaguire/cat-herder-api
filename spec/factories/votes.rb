FactoryBot.define do
  factory :vote do
    association :user
    association :event
    chosen_slot { Date.today.to_s }
  end
end
