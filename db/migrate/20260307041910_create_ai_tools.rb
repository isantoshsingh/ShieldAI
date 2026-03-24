class CreateAiTools < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_tools do |t|
      t.references :organisation, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :domain, null: false
      t.string :category, null: false
      t.string :icon_emoji, null: false, default: "🤖"
      t.boolean :approved, null: false, default: false

      t.timestamps null: false
    end

    add_index :ai_tools, [:organisation_id, :domain], unique: true
  end
end
