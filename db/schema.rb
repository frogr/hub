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

ActiveRecord::Schema[8.0].define(version: 2025_06_01_102819) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "passwordless_sessions", force: :cascade do |t|
    t.string "authenticatable_type"
    t.integer "authenticatable_id"
    t.string "token"
    t.string "user_agent"
    t.string "remote_addr"
    t.datetime "expires_at"
    t.datetime "timeout_at"
    t.datetime "claimed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authenticatable_type", "authenticatable_id"], name: "idx_on_authenticatable_type_authenticatable_id_c2bc1b4f4e"
    t.index ["token"], name: "index_passwordless_sessions_on_token", unique: true
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "stripe_price_id"
    t.integer "amount", null: false
    t.string "currency", default: "usd", null: false
    t.string "interval", null: false
    t.text "features"
    t.integer "trial_days", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_price_id"], name: "index_plans_on_stripe_price_id", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "stripe_subscription_id"
    t.string "status", default: "active", null: false
    t.datetime "current_period_end"
    t.boolean "cancel_at_period_end", default: false
    t.string "stripe_customer_id"
    t.bigint "plan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "trial_ends_at"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "passwordless_login_enabled", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_customer_id"
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.string "event_type"
    t.string "event_id"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_webhooks_on_event_id", unique: true
  end

  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "users"
end
