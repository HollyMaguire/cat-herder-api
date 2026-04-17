# db/seeds.rb
#
# Run with: rails db:seed
# Re-seed cleanly: rails db:drop db:create db:migrate db:seed
#
# Creates realistic test data covering every feature in the frontend:
#   - 3 users
#   - 4 events with different items_mode and vote_mode combinations
#   - Invites, items, and availability submissions

puts "Seeding Cat Herder..."

# ── Users ──────────────────────────────────────────────────────────────────
alice = User.create!(
  username:     "admin",
  email:        "admin@test.com",
  contact_type: "email"
)

bob = User.create!(
  username:     "guest",
  email:        "guest@test.com",
  contact_type: "email"
)

sarah = User.create!(
  username:     "sarah",
  phone:        "222-222-2222",
  contact_type: "phone"
)

puts "  Created 3 users: admin, guest, sarah"

# ── Event 1: Potluck — open items, host picks ties ─────────────────────────
potluck = Event.create!(
  owner:            alice,
  name:             "Summer Potluck",
  description:      "Bring a dish to share! Hosted at Alice's backyard.",
  vote_mode:        false,
  items_mode:       "open",
  date_range_start: Date.new(2025, 8, 1),
  date_range_end:   Date.new(2025, 8, 15),
  status:           "open"
)

Item.create!([
  { event: potluck, name: "Pasta salad" },
  { event: potluck, name: "Drinks" },
  { event: potluck, name: "Dessert" },
  { event: potluck, name: "Bread" },
])

Invite.create!(event: potluck, contact: bob.email,   contact_type: "email", user: bob,   status: "accepted")
Invite.create!(event: potluck, contact: sarah.phone, contact_type: "phone", user: sarah, status: "pending")

Availability.create!(user: bob,   event: potluck, slots: ["2025-08-05", "2025-08-10", "2025-08-14"])
Availability.create!(user: sarah, event: potluck, slots: ["2025-08-10", "2025-08-14"])

puts "  Created: Summer Potluck (open items, 2 guests)"

# ── Event 2: Birthday — gift mode, group votes on ties ────────────────────
birthday = Event.create!(
  owner:            bob,
  name:             "Sarah's Birthday",
  description:      "Surprise party for Sarah! Don't let her see the gift list.",
  vote_mode:        true,
  items_mode:       "gift",
  gift_hidden_from: "sarah",
  date_range_start: Date.new(2025, 9, 1),
  date_range_end:   Date.new(2025, 9, 30),
  status:           "open"
)

Item.create!([
  { event: birthday, name: "Amazon gift card" },
  { event: birthday, name: "Spa voucher" },
  { event: birthday, name: "Book" },
])

# Mark alice's item as claimed
Item.find_by(event: birthday, name: "Amazon gift card").update!(claimed_by: alice)

Invite.create!(event: birthday, contact: alice.email,  contact_type: "email", user: alice, status: "accepted", is_vip: false)
Invite.create!(event: birthday, contact: sarah.phone,  contact_type: "phone", user: sarah, status: "accepted", is_vip: true)

Availability.create!(user: alice, event: birthday, slots: ["2025-09-06", "2025-09-13", "2025-09-20"])
Availability.create!(user: sarah, event: birthday, slots: ["2025-09-06", "2025-09-13"])

puts "  Created: Sarah's Birthday (gift mode, VIP=sarah, group voting)"

# ── Event 3: Work meetup — surprise mode, confirmed date ─────────────────
meetup = Event.create!(
  owner:            alice,
  name:             "Team Meetup Q3",
  description:      "Quarterly in-person team day.",
  vote_mode:        false,
  items_mode:       "simpleYes",
  date_range_start: Date.new(2025, 7, 14),
  date_range_end:   Date.new(2025, 7, 18),
  confirmed_date:   "2025-07-16",
  status:           "confirmed"
)

Invite.create!(event: meetup, contact: bob.email,   contact_type: "email", user: bob,   status: "accepted")
Invite.create!(event: meetup, contact: sarah.phone, contact_type: "phone", user: sarah, status: "declined")

puts "  Created: Team Meetup Q3 (surprise mode, confirmed 2025-07-16)"

# ── Event 4: Housewarming — no items, fresh invites not yet claimed ───────
housewarming = Event.create!(
  owner:            sarah,
  name:             "Housewarming Party",
  description:      "Come see the new place! Just bring yourselves.",
  vote_mode:        false,
  items_mode:       "none",
  date_range_start: Date.new(2025, 10, 1),
  date_range_end:   Date.new(2025, 10, 31),
  status:           "open"
)

# Alice and Bob invited but haven't signed up yet — simulates pre-account invites
Invite.create!(event: housewarming, contact: "alice@example.com", contact_type: "email", user: alice, status: "pending")
Invite.create!(event: housewarming, contact: "bob@example.com",   contact_type: "email", user: bob,   status: "pending")
Invite.create!(event: housewarming, contact: "newperson@email.com", contact_type: "email", status: "pending")

puts "  Created: Housewarming Party (no items, 1 invite not yet claimed)"

puts ""
puts "Seed complete! Summary:"
puts "  Users:  #{User.count}"
puts "  Events: #{Event.count}"
puts "  Invites: #{Invite.count}"
puts "  Items:   #{Item.count}"
puts "  Availabilities: #{Availability.count}"
puts ""
puts "Test login credentials:"
puts "  admin@test.com  (email)"
puts "  guest@test.com  (email)"
puts "  222-222-2222    (phone, sarah)"
