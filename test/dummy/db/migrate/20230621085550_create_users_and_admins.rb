class CreateUsersAndAdmins < ActiveRecord::Migration[6.0]
  def change
    create_table(:admins) do |t|
      t.string(:email)

      t.timestamps
    end

    create_table(:users) do |t|
      t.string(:email)

      t.timestamps
    end

    add_index(:admins, :email, unique: true)
    add_index(:users, :email, unique: true)
  end
end
