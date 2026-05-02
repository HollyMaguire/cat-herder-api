class AddInviteTokenToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :invite_token, :string
    add_index  :events, :invite_token, unique: true
    Event.find_each { |e| e.update_columns(invite_token: SecureRandom.urlsafe_base64(12)) }
    change_column_null :events, :invite_token, false
  end
end
