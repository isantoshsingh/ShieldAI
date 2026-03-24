class CreateDetectionEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :detection_events do |t|
      t.references :organisation, null: false, foreign_key: { on_delete: :cascade }
      t.references :employee, null: false, foreign_key: { on_delete: :cascade }
      t.references :ai_tool, null: false, foreign_key: { on_delete: :cascade }
      t.string :page_title
      t.datetime :detected_at, null: false

      t.timestamps null: false
    end

    add_index :detection_events, [:organisation_id, :detected_at]
    add_index :detection_events, [:employee_id, :detected_at]
    add_index :detection_events, [:ai_tool_id, :detected_at]
    add_index :detection_events, :detected_at
  end
end
