class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :username,     null: false
      t.string :email
      t.string :phone
      t.string :contact_type, null: false

      t.timestamps
    end
    add_index :users, :username, unique: true
    add_index :users, :email,    unique: true
    add_index :users, :phone,    unique: true
  end
end
