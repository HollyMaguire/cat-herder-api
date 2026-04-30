class AddCustomDatesToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :custom_dates, :json, default: []
  end
end
