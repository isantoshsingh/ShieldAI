# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_07_095006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_tools", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "domain", null: false
    t.string "icon_emoji", default: "🤖", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_ai_tools_on_domain", unique: true
  end

  create_table "daily_summaries", force: :cascade do |t|
    t.bigint "ai_tool_id", null: false
    t.datetime "created_at", null: false
    t.bigint "employee_id", null: false
    t.bigint "organisation_id", null: false
    t.integer "session_count", default: 0, null: false
    t.date "summary_date", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_tool_id"], name: "index_daily_summaries_on_ai_tool_id"
    t.index ["employee_id"], name: "index_daily_summaries_on_employee_id"
    t.index ["organisation_id", "employee_id", "ai_tool_id", "summary_date"], name: "idx_daily_summaries_unique", unique: true
    t.index ["organisation_id"], name: "index_daily_summaries_on_organisation_id"
  end

  create_table "detection_events", force: :cascade do |t|
    t.bigint "ai_tool_id", null: false
    t.datetime "created_at", null: false
    t.datetime "detected_at", null: false
    t.bigint "employee_id", null: false
    t.bigint "organisation_id", null: false
    t.string "page_title"
    t.datetime "updated_at", null: false
    t.index ["ai_tool_id", "detected_at"], name: "index_detection_events_on_ai_tool_id_and_detected_at"
    t.index ["ai_tool_id"], name: "index_detection_events_on_ai_tool_id"
    t.index ["detected_at"], name: "index_detection_events_on_detected_at"
    t.index ["employee_id", "detected_at"], name: "index_detection_events_on_employee_id_and_detected_at"
    t.index ["employee_id"], name: "index_detection_events_on_employee_id"
    t.index ["organisation_id", "detected_at"], name: "index_detection_events_on_organisation_id_and_detected_at"
    t.index ["organisation_id"], name: "index_detection_events_on_organisation_id"
  end

  create_table "employees", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "department"
    t.string "email", null: false
    t.string "extension_token", null: false
    t.string "name", null: false
    t.bigint "organisation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["extension_token"], name: "index_employees_on_extension_token", unique: true
    t.index ["organisation_id", "email"], name: "index_employees_on_organisation_id_and_email", unique: true
    t.index ["organisation_id"], name: "index_employees_on_organisation_id"
  end

  create_table "organisation_ai_tools", force: :cascade do |t|
    t.bigint "ai_tool_id", null: false
    t.boolean "approved", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "organisation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_tool_id"], name: "index_organisation_ai_tools_on_ai_tool_id"
    t.index ["organisation_id", "ai_tool_id"], name: "index_organisation_ai_tools_on_organisation_id_and_ai_tool_id", unique: true
    t.index ["organisation_id"], name: "index_organisation_ai_tools_on_organisation_id"
  end

  create_table "organisations", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organisations_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.bigint "organisation_id"
    t.datetime "remember_created_at"
    t.string "role", default: "org_member", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "daily_summaries", "ai_tools", on_delete: :cascade
  add_foreign_key "daily_summaries", "employees", on_delete: :cascade
  add_foreign_key "daily_summaries", "organisations", on_delete: :cascade
  add_foreign_key "detection_events", "ai_tools", on_delete: :cascade
  add_foreign_key "detection_events", "employees", on_delete: :cascade
  add_foreign_key "detection_events", "organisations", on_delete: :cascade
  add_foreign_key "employees", "organisations", on_delete: :cascade
  add_foreign_key "organisation_ai_tools", "ai_tools", on_delete: :cascade
  add_foreign_key "organisation_ai_tools", "organisations", on_delete: :cascade
  add_foreign_key "users", "organisations", on_delete: :cascade
end
