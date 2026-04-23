class Invite < ApplicationRecord
  belongs_to :event
  belongs_to :user, optional: true

  validates :contact,      presence: true
  validates :contact_type, inclusion: { in: %w[email phone username] }
  validates :status,       inclusion: { in: %w[pending accepted declined maybe] }
  validates :contact,      uniqueness: { scope: :event_id, message: "already invited to this event" }

  def self.claim_for_user(user)
    contact_val = user.contact_type == "email" ? user.email : user.phone
    where(contact: contact_val, contact_type: user.contact_type, user_id: nil).update_all(user_id: user.id)
    where("LOWER(contact) = ? AND contact_type = 'username' AND user_id IS NULL", user.username.downcase).update_all(user_id: user.id)
  end
end
