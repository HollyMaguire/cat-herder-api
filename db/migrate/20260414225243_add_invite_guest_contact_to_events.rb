class AddInviteGuestContactToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :invite_guest_contact, :string
  end
end
