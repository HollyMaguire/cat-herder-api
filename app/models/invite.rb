# app/models/invite.rb
class Invite < ApplicationRecord
  belongs_to :event
  belongs_to :user, optional: true  # nil until the invitee logs in and claims it

  validates :contact,      presence: true
  validates :contact_type, inclusion: { in: %w[email phone username] }
  validates :status,       inclusion: { in: %w[pending accepted declined maybe] }
  validates :contact,      uniqueness: { scope: :event_id, message: "already invited to this event" }

  # Called at login/register — links all un-owned invites matching this user's contact.
  def self.claim_for_user(user)
    contact_val = user.contact_type == "email" ? user.email : user.phone
    where(contact: contact_val, contact_type: user.contact_type, user_id: nil).update_all(user_id: user.id)
    where(contact: user.username, contact_type: "username", user_id: nil).update_all(user_id: user.id)
  end
end
