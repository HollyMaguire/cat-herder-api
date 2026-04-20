FactoryBot.define do
  factory :event do
    association :owner, factory: :user
    sequence(:name) { |n| "Event #{n}" }
    date_range_start { Date.today + 7 }
    date_range_end   { Date.today + 14 }
    items_mode       { "none" }
    status           { "open" }
    invite_permission { "host" }
    vip_permission    { "host" }
    start_time_mode   { "none" }
    vote_mode         { false }
  end
end
