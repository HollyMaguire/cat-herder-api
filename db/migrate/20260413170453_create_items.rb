class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name
      t.references :event, null: false, foreign_key: true
      t.integer :claimed_by_id

      t.timestamps
    end
  end
end
