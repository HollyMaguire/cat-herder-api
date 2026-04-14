class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string  :name,             null: false
      t.text    :description
      t.boolean :vote_mode,        null: false, default: false
      t.string  :items_mode,       null: false, default: 'none'
      t.string  :gift_hidden_from
      t.date    :date_range_start
      t.date    :date_range_end
      t.date    :confirmed_date
      t.string  :status,           null: false, default: 'open'
      t.integer :owner_id,         null: false

      t.timestamps
    end
    add_index :events, :owner_id
    add_foreign_key :events, :users, column: :owner_id
  end
end
