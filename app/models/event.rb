# app/models/event.rb
class Event < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many   :invites,        dependent: :destroy
  has_many   :invited_users,  through: :invites, source: :user
  has_many   :items,          dependent: :destroy
  has_many   :availabilities, dependent: :destroy
  has_many   :votes,          dependent: :destroy

  validates :name,       presence: true, length: { maximum: 120 }
  validates :items_mode, inclusion: { in: %w[none open gift surprise] }
  validates :status,     inclusion: { in: %w[open confirmed cancelled] }
  validate  :end_date_after_start

  # ── Availability aggregation ─────────────────────────────────────────────
  #
  # Returns an array of hashes sorted best-first:
  #   [{ slot: "2025-08-14", count: 5, vip_count: 2 }, ...]
  #
  # VIP users (invites where is_vip=true) are weighted first.
  def availability_results
    vip_user_ids = invites.where(is_vip: true).pluck(:user_id).compact

    slot_map = Hash.new { |h, k| h[k] = { count: 0, vip_count: 0 } }

    availabilities.each do |avail|
      Array(avail.slots).each do |slot|
        slot_map[slot][:count] += 1
        slot_map[slot][:vip_count] += 1 if vip_user_ids.include?(avail.user_id)
      end
    end

    slot_map
      .map { |slot, data| { slot: slot, count: data[:count], vip_count: data[:vip_count] } }
      .sort_by { |s| [-s[:vip_count], -s[:count]] }
  end

  # ── Tie detection ─────────────────────────────────────────────────────────
  def tied_slots
    results = availability_results
    return [] if results.empty?

    top = results.first
    results.select { |s| s[:count] == top[:count] && s[:vip_count] == top[:vip_count] }
  end

  def tie?
    tied_slots.length > 1
  end

  private

  def end_date_after_start
    return unless date_range_start && date_range_end
    if date_range_end < date_range_start
      errors.add(:date_range_end, "must be after the start date")
    end
  end
end
