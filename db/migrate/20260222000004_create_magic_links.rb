class CreateMagicLinks < ActiveRecord::Migration[7.2]
  def change
    create_table :magic_links, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.datetime :created_at, null: false
    end

    add_index :magic_links, :token, unique: true
  end
end
