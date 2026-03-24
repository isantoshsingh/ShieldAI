class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.references :organisation, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :email, null: false
      t.string :department
      t.string :extension_token, null: false
      t.boolean :active, null: false, default: true

      t.timestamps null: false
    end

    add_index :employees, :extension_token, unique: true
    add_index :employees, [:organisation_id, :email], unique: true
  end
end
