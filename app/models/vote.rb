class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :chosen_slot, presence: true
  validates :vote_type,   inclusion: { in: %w[date time] }
  validates :user_id,     uniqueness: { scope: [ :event_id, :vote_type ], message: "has already voted on this event" }
  validate  :slot_must_be_valid

  private

  def slot_must_be_valid
    return unless event

    if vote_type == "time"
      date        = chosen_slot&.split("T")&.first
      return unless date
      date_group  = event.availability_results.find { |r| r[:slot] == date }
      valid_slots = date_group ? date_group[:times].map { |t| t[:slot] } : []
      unless valid_slots.include?(chosen_slot)
        errors.add(:chosen_slot, "is not a valid time option for that date")
      end
    else
      tied_slots = event.tied_slots.map { |s| s[:slot] }
      unless tied_slots.include?(chosen_slot)
        errors.add(:chosen_slot, "is not one of the tied slots available to vote on")
      end
    end
  end
end
