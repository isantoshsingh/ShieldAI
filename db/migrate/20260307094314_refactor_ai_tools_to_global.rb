class RefactorAiToolsToGlobal < ActiveRecord::Migration[8.1]
  def change
    # 1. Create the join table
    create_table :organisation_ai_tools do |t|
      t.references :organisation, null: false, foreign_key: { on_delete: :cascade }
      t.references :ai_tool, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :approved, null: false, default: false

      t.timestamps null: false
    end

    add_index :organisation_ai_tools, [:organisation_id, :ai_tool_id], unique: true

    # 2. Migrate existing data: create join records from current ai_tools
    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO organisation_ai_tools (organisation_id, ai_tool_id, approved, created_at, updated_at)
          SELECT organisation_id, id, approved, created_at, updated_at
          FROM ai_tools
          WHERE organisation_id IS NOT NULL
        SQL

        # Deduplicate ai_tools: keep only one per domain (the lowest id)
        execute <<~SQL
          DELETE FROM ai_tools
          WHERE id NOT IN (
            SELECT MIN(id) FROM ai_tools GROUP BY domain
          )
        SQL
      end
    end

    # 3. Remove organisation-specific columns from ai_tools
    remove_index :ai_tools, [:organisation_id, :domain]
    remove_reference :ai_tools, :organisation, foreign_key: true
    remove_column :ai_tools, :approved, :boolean

    # 4. Add global unique index on domain
    add_index :ai_tools, :domain, unique: true
  end
end
