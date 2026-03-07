# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Rememberable
      t.datetime :remember_created_at

      t.references :organisation, null: true, foreign_key: { on_delete: :cascade }
      t.string :role, null: false, default: "org_admin"
      t.string :name, null: false

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :role
  end
end
