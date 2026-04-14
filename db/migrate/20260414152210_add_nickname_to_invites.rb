class AddNicknameToInvites < ActiveRecord::Migration[8.0]
  def change
    add_column :invites, :nickname, :string
  end
end
