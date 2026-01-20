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

ActiveRecord::Schema[8.1].define(version: 2026_01_20_104643) do
  create_table "backup_runs", force: :cascade do |t|
    t.integer "backup_id", null: false
    t.datetime "created_at", null: false
    t.string "destination_rclone_path"
    t.boolean "dry_run", default: false, null: false
    t.integer "exit_code"
    t.datetime "finished_at"
    t.integer "rclone_pid"
    t.integer "source_bytes"
    t.integer "source_count"
    t.string "source_rclone_path"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["backup_id", "status"], name: "index_backup_runs_on_backup_id_and_status"
    t.index ["backup_id"], name: "index_backup_runs_on_backup_id"
    t.index ["status"], name: "index_backup_runs_on_status"
  end

  create_table "backups", force: :cascade do |t|
    t.integer "comparison_mode", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "destination_path"
    t.integer "destination_storage_id", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "last_run_at"
    t.string "name", null: false
    t.integer "retention_days", default: 30, null: false
    t.string "schedule", default: "daily", null: false
    t.string "source_path"
    t.integer "source_storage_id", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_storage_id"], name: "index_backups_on_destination_storage_id"
    t.index ["source_storage_id"], name: "index_backups_on_source_storage_id"
  end

  create_table "notifiers", force: :cascade do |t|
    t.text "config"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true
    t.string "last_error"
    t.datetime "last_failed_at"
    t.datetime "last_notified_at"
    t.string "name", null: false
    t.boolean "notify_on_failure", default: true, null: false
    t.boolean "notify_on_success", default: false, null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
  end

  create_table "providers", force: :cascade do |t|
    t.string "access_key_id", null: false
    t.datetime "created_at", null: false
    t.string "endpoint"
    t.string "name", null: false
    t.string "provider_type", null: false
    t.string "region"
    t.string "secret_access_key", null: false
    t.datetime "updated_at", null: false
  end

  create_table "storages", force: :cascade do |t|
    t.string "bucket_name", null: false
    t.datetime "created_at", null: false
    t.string "display_name"
    t.integer "provider_id", null: false
    t.datetime "updated_at", null: false
    t.integer "usage_type"
    t.index ["provider_id", "bucket_name"], name: "index_storages_on_provider_id_and_bucket_name", unique: true
    t.index ["provider_id"], name: "index_storages_on_provider_id"
  end

  add_foreign_key "backup_runs", "backups"
  add_foreign_key "backups", "storages", column: "destination_storage_id"
  add_foreign_key "backups", "storages", column: "source_storage_id"
  add_foreign_key "storages", "providers"
end
