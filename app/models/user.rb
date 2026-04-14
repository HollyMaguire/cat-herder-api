# app/models/user.rb
class User < ApplicationRecord
  has_many :owned_events,   class_name: "Event", foreign_key: :owner_id, dependent: :destroy
  has_many :invites,        dependent: :destroy
  has_many :invited_events, through: :invites, source: :event
  has_many :availabilities, dependent: :destroy
  has_many :votes,          dependent: :destroy
  has_many :claimed_items,  class_name: "Item", foreign_key: :claimed_by_id

  validates :username,     presence: true, uniqueness: { case_sensitive: false },
                           format: { with: /\A[a-zA-Z0-9_]+\z/, message: "letters, numbers, underscores only" },
                           length: { minimum: 3, maximum: 30 }
  validates :contact_type, inclusion: { in: %w[email phone] }
  validates :email,        format: { with: URI::MailTo::EMAIL_REGEXP },
                           uniqueness: { case_sensitive: false },
                           allow_blank: true
  validates :phone,        format: { with: /\A\+?[\d\s\-(). ]{7,20}\z/ },
                           uniqueness: true,
                           allow_blank: true
  validate  :email_or_phone_present

  before_save :normalize_contact

  # Find by whichever contact field was provided
  def self.find_by_contact(contact, type)
    type == "email" ? find_by(email: contact.downcase.strip) : find_by(phone: contact.strip)
  end

  private

  def email_or_phone_present
    errors.add(:base, "Email or phone number is required") if email.blank? && phone.blank?
  end

  def normalize_contact
    self.email = email.downcase.strip if email.present?
    self.phone = phone.strip          if phone.present?
  end
end
