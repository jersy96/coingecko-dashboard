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

ActiveRecord::Schema[8.1].define(version: 2026_09_30_210000) do
  create_table "auditing_activity_entries", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "action", null: false
    t.string "subject", null: false
    t.json "details", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_auditing_activity_entries_on_action"
    t.index ["occurred_at"], name: "index_auditing_activity_entries_on_occurred_at"
    t.index ["user_id"], name: "index_auditing_activity_entries_on_user_id"
  end

  create_table "market_feed_thresholds", force: :cascade do |t|
    t.string "kind", null: false
    t.decimal "alert_value", precision: 20, scale: 4
    t.decimal "good_value", precision: 20, scale: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_market_feed_thresholds_on_kind", unique: true
  end

  create_table "market_feed_watchlist_items", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "asset_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "asset_id"], name: "index_market_feed_watchlist_items_on_user_id_and_asset_id", unique: true
    t.index ["user_id"], name: "index_market_feed_watchlist_items_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "auditing_activity_entries", "users"
  add_foreign_key "market_feed_watchlist_items", "users"
end
