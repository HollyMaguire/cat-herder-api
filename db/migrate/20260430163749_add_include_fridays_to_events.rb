class AddIncludeFridaysToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :include_fridays, :boolean, default: false, null: false
  end
end
