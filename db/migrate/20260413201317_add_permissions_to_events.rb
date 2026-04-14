class AddPermissionsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :invite_permission, :string
    add_column :events, :vip_permission, :string
  end
end
