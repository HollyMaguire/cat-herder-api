class ChangeConfirmedDateToString < ActiveRecord::Migration[8.0]
  def up
    change_column :events, :confirmed_date, :string
  end

  def down
    change_column :events, :confirmed_date, :date
  end
end
