class Item < ApplicationRecord
  belongs_to :event
  belongs_to :claimed_by, class_name: "User", optional: true
  belongs_to :added_by,   class_name: "User", optional: true

  scope :claimed,   -> { where.not(claimed_by_id: nil) }
  scope :unclaimed, -> { where(claimed_by_id: nil) }

  validates :name, presence: true, length: { maximum: 120 }
end
