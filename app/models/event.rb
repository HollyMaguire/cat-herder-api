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
    declined_user_ids   = invites.where(status: "declined").pluck(:user_id).compact
    active_avails       = declined_user_ids.any? ? availabilities.where.not(user_id: declined_user_ids) : availabilities
    vip_user_ids        = invites.where(is_vip: true).where.not(status: "declined").pluck(:user_id).compact
    vips_have_submitted = vip_user_ids.any? &&
                          active_avails.where(user_id: vip_user_ids).exists?

    # date_map[date] = { user_ids: {id=>true}, vip_user_ids: {id=>true}, times: {slot=>{count:,vip_count:}} }
    date_map = Hash.new { |h, k| h[k] = { user_ids: {}, vip_user_ids: {}, times: {} } }

    active_avails.each do |avail|
      is_vip = vip_user_ids.include?(avail.user_id)
      Array(avail.slots).each do |slot|
        date = slot.include?("T") ? slot.split("T")[0] : slot
        date_map[date][:user_ids][avail.user_id]     = true
        date_map[date][:vip_user_ids][avail.user_id] = true if is_vip
        if slot.include?("T")
          date_map[date][:times][slot] ||= { count: 0, vip_count: 0 }
          date_map[date][:times][slot][:count]     += 1
          date_map[date][:times][slot][:vip_count] += 1 if is_vip
        end
      end
    end

    all_results = date_map.map do |date, data|
      count     = data[:user_ids].size
      vip_count = data[:vip_user_ids].size
      times     = data[:times].map { |slot, t| { slot: slot, count: t[:count], vip_count: t[:vip_count] } }
                              .sort_by { |t| -t[:count] }
      {
        slot:         date,
        count:        count,
        vip_count:    vip_count,
        vip_eligible: !vips_have_submitted || vip_count > 0,
        times:        times,
      }
    end

    if vips_have_submitted
      vip_slots   = all_results.select { |s| s[:vip_count] > 0 }.sort_by { |s| -s[:count] }
      other_slots = all_results.select { |s| s[:vip_count] == 0 }.sort_by { |s| -s[:count] }
      vip_slots + other_slots
    else
      all_results.sort_by { |s| [ -s[:vip_count], -s[:count] ] }
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

  def time_slots_for(date)
    date_group = availability_results.find { |r| r[:slot] == date }
    date_group ? date_group[:times] : []
  end

  def time_tied_slots(date)
    times = time_slots_for(date)
    return [] if times.empty?
    top_count = times.map { |t| t[:count] }.max
    times.select { |t| t[:count] == top_count }
  end

  def time_tie?(date)
    time_tied_slots(date).length > 1
  end

  def time_vote_closed?(date)
    participating_ids = availabilities.pluck(:user_id)
    return true if participating_ids.empty?
    voted_ids = votes.where(vote_type: "time").where("chosen_slot LIKE ?", "#{date}%").pluck(:user_id)
    (participating_ids - voted_ids).empty?
  end

  def tie_vote_closed?
    declined_user_ids = invites.where(status: "declined").pluck(:user_id).compact
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

    invited_user_ids  = invites.where.not(user_id: nil).where.not(status: "declined").pluck(:user_id)
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
