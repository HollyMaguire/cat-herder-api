class AddBringLabelToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :bring_label, :string
  end
end
