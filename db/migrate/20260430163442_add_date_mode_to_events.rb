class AddDateModeToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :date_mode, :string, default: 'range'
  end
end
