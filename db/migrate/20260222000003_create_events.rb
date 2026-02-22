class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :ai_tool, type: :uuid, null: true, foreign_key: true
      t.string :domain, null: false
      t.string :page_title
      t.datetime :detected_at, null: false
      t.string :session_id
      t.datetime :created_at, null: false
    end

    add_index :events, [:user_id, :detected_at]
    add_index :events, :detected_at
  end
end
