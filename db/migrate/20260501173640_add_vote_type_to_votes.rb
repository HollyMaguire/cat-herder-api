class AddVoteTypeToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :vote_type, :string, default: "date", null: false
  end
end
