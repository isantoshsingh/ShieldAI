class CreateDailySummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_summaries do |t|
      t.references :organisation, null: false, foreign_key: { on_delete: :cascade }
      t.references :employee, null: false, foreign_key: { on_delete: :cascade }
      t.references :ai_tool, null: false, foreign_key: { on_delete: :cascade }
      t.date :summary_date, null: false
      t.integer :session_count, null: false, default: 0

      t.timestamps null: false
    end

    add_index :daily_summaries, [:organisation_id, :employee_id, :ai_tool_id, :summary_date], unique: true, name: "idx_daily_summaries_unique"
  end
end
