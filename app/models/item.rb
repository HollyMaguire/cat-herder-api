class Item < ApplicationRecord
  belongs_to :event
  belongs_to :claimed_by, class_name: "User", optional: true
  belongs_to :added_by,   class_name: "User", optional: true

  validates :name, presence: true, length: { maximum: 120 }
end
