class Event < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many   :invites,        dependent: :destroy
  has_many   :invited_users,  through: :invites, source: :user
  has_many   :items,          dependent: :destroy
  has_many   :availabilities, dependent: :destroy
  has_many   :votes,          dependent: :destroy

  validates :name,       presence: true, length: { maximum: 120 }
  validates :items_mode, inclusion: { in: %w[none open gift simpleYes] }
  validates :status,     inclusion: { in: %w[open confirmed cancelled] }
  validate  :end_date_after_start

  def availability_results
    declined_user_ids   = invites.where(status: 'declined').pluck(:user_id).compact
    active_avails       = declined_user_ids.any? ? availabilities.where.not(user_id: declined_user_ids) : availabilities
    vip_user_ids        = invites.where(is_vip: true).where.not(status: 'declined').pluck(:user_id).compact
    vips_have_submitted = vip_user_ids.any? &&
                          active_avails.where(user_id: vip_user_ids).exists?

    slot_map = Hash.new { |h, k| h[k] = { count: 0, vip_count: 0 } }

    active_avails.each do |avail|
      Array(avail.slots).each do |slot|
        slot_map[slot][:count]     += 1
        slot_map[slot][:vip_count] += 1 if vip_user_ids.include?(avail.user_id)
      end
    end

    all_results = slot_map.map do |slot, data|
      {
        slot:         slot,
        count:        data[:count],
        vip_count:    data[:vip_count],
        vip_eligible: !vips_have_submitted || data[:vip_count] > 0,
      }
    end

    if vips_have_submitted
      vip_slots   = all_results.select { |s| s[:vip_count] > 0 }.sort_by { |s| -s[:count] }
      other_slots = all_results.select { |s| s[:vip_count] == 0 }.sort_by { |s| -s[:count] }
      vip_slots + other_slots
    else
      all_results.sort_by { |s| [-s[:vip_count], -s[:count]] }
    end
  end

  def tied_slots
    results = availability_results
    return [] if results.empty?

    eligible = results.select { |s| s[:vip_eligible] }
    return [] if eligible.empty?

    top_count = eligible.first[:count]
    eligible.select { |s| s[:count] == top_count }
  end

  def tie?
    tied_slots.length > 1
  end

  def tie_vote_closed?
    declined_user_ids = invites.where(status: 'declined').pluck(:user_id).compact
    participating_ids = declined_user_ids.any? \
      ? availabilities.where.not(user_id: declined_user_ids).pluck(:user_id)
      : availabilities.pluck(:user_id)
    return true if participating_ids.empty?
    voted_user_ids = votes.pluck(:user_id)
    (participating_ids - voted_user_ids).empty?
  end

  def results_ready?
    return false if availabilities.none?
    return true  if availability_deadline && Date.today >= availability_deadline

    invited_user_ids  = invites.where.not(user_id: nil).where.not(status: 'declined').pluck(:user_id)
    return true if invited_user_ids.empty?

    submitted_user_ids = availabilities.pluck(:user_id)
    (invited_user_ids - submitted_user_ids).empty?
  end

  private

  def end_date_after_start
    return unless date_range_start && date_range_end
    if date_range_end < date_range_start
      errors.add(:date_range_end, "must be after the start date")
    end
  end
end
