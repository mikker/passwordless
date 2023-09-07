class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
