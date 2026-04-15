class AddTypeFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :gift_hidden_from_type, :string
    add_column :events, :invite_guest_contact_type, :string
  end
end
