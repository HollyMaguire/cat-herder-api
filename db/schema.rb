# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_01_173640) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "availabilities", force: :cascade do |t|
    t.json "slots"
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_availabilities_on_event_id"
    t.index ["user_id"], name: "index_availabilities_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "vote_mode", default: false, null: false
    t.string "items_mode", default: "none", null: false
    t.string "gift_hidden_from"
    t.date "date_range_start"
    t.date "date_range_end"
    t.string "confirmed_date"
    t.string "status", default: "open", null: false
    t.integer "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invite_permission"
    t.string "vip_permission"
    t.string "start_time_mode"
    t.string "start_time"
    t.string "invite_guest_contact"
    t.string "gift_hidden_from_type"
    t.string "invite_guest_contact_type"
    t.string "bring_label"
    t.date "availability_deadline"
    t.string "date_mode", default: "range"
    t.boolean "include_fridays", default: false, null: false
    t.json "custom_dates", default: []
    t.index ["owner_id"], name: "index_events_on_owner_id"
  end

  create_table "invites", force: :cascade do |t|
    t.string "contact"
    t.string "contact_type"
    t.string "status", default: "pending", null: false
    t.boolean "is_vip", default: false, null: false
    t.integer "event_id", null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nickname"
    t.index ["event_id"], name: "index_invites_on_event_id"
    t.index ["user_id"], name: "index_invites_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.integer "event_id", null: false
    t.integer "claimed_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "added_by_id"
    t.index ["added_by_id"], name: "index_items_on_added_by_id"
    t.index ["event_id"], name: "index_items_on_event_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email"
    t.string "phone"
    t.string "contact_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.string "password_digest"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.string "chosen_slot"
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "vote_type", default: "date", null: false
    t.index ["event_id"], name: "index_votes_on_event_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "availabilities", "events"
  add_foreign_key "availabilities", "users"
  add_foreign_key "events", "users", column: "owner_id"
  add_foreign_key "invites", "events"
  add_foreign_key "invites", "users"
  add_foreign_key "items", "events"
  add_foreign_key "votes", "events"
  add_foreign_key "votes", "users"
end
