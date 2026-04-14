# app/models/availability.rb
class Availability < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :slots, presence: true
  validate  :slots_within_date_range
  validate  :slots_are_valid_dates

  private

  def slots_within_date_range
    return unless event&.date_range_start && event&.date_range_end

    Array(slots).each do |slot|
      date = Date.parse(slot) rescue nil
      next unless date
      unless date >= event.date_range_start && date <= event.date_range_end
        errors.add(:slots, "#{slot} is outside the event's date window " \
                           "(#{event.date_range_start} – #{event.date_range_end})")
      end
    end
  end

  def slots_are_valid_dates
    Array(slots).each do |slot|
      Date.parse(slot) rescue errors.add(:slots, "\"#{slot}\" is not a valid date")
    end
  end
end
