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

ActiveRecord::Schema[8.1].define(version: 2026_11_10_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "entries", force: :cascade do |t|
    t.bigint "window_id", null: false
    t.date "recorded_on", null: false
    t.integer "attempted_count", default: 0, null: false
    t.integer "achieved_count", default: 0, null: false
    t.string "title"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["window_id", "recorded_on"], name: "index_entries_on_window_id_and_recorded_on"
    t.index ["window_id"], name: "index_entries_on_window_id"
  end

  create_table "phases", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "code"], name: "index_phases_on_user_id_and_code", unique: true
    t.index ["user_id"], name: "index_phases_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.bigint "window_id", null: false
    t.string "title", null: false
    t.datetime "done_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["window_id"], name: "index_plans_on_window_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "windows", force: :cascade do |t|
    t.bigint "phase_id", null: false
    t.integer "number", null: false
    t.string "title", null: false
    t.integer "measure", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phase_id", "number"], name: "index_windows_on_phase_id_and_number", unique: true
    t.index ["phase_id"], name: "index_windows_on_phase_id"
  end

  add_foreign_key "entries", "windows"
  add_foreign_key "phases", "users"
  add_foreign_key "plans", "windows"
  add_foreign_key "windows", "phases"
end
