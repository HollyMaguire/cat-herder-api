class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites do |t|
      t.string :contact
      t.string :contact_type
      t.string  :status,  null: false, default: 'pending'
      t.boolean :is_vip,  null: false, default: false
      t.references :event, null: false, foreign_key: true
      t.references :user,  foreign_key: true

      t.timestamps
    end
  end
end
