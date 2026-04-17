class AddAvailabilityDeadlineToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :availability_deadline, :date
  end
end
