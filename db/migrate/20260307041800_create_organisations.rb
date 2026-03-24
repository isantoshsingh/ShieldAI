class CreateOrganisations < ActiveRecord::Migration[8.1]
  def change
    create_table :organisations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.boolean :active, null: false, default: true

      t.timestamps null: false
    end

    add_index :organisations, :slug, unique: true
  end
end
