class CreateAiTools < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_tools, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :name, null: false
      t.string :domain, null: false
      t.string :category
      t.string :risk_level, default: "medium"
      t.boolean :approved, default: false
      t.datetime :created_at, null: false
    end

    add_index :ai_tools, :domain, unique: true
  end
end
