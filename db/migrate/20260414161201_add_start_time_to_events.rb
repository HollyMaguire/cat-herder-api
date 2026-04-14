class AddStartTimeToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :start_time_mode, :string
    add_column :events, :start_time, :string
  end
end
