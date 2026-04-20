class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :chosen_slot, presence: true
  validates :user_id, uniqueness: { scope: :event_id, message: "has already voted on this event" }
  validate  :slot_must_be_tied

  private

  def slot_must_be_tied
    return unless event

    tied_slots = event.tied_slots.map { |s| s[:slot] }
    unless tied_slots.include?(chosen_slot)
      errors.add(:chosen_slot, "is not one of the tied slots available to vote on")
    end
  end
end
