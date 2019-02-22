# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2017_11_04_225303) do
  create_table "passwordless_sessions", force: :cascade do |t|
    t.string "authenticatable_type"
    t.integer "authenticatable_id"
    t.datetime "timeout_at", null: false
    t.datetime "expires_at", null: false
    t.text "user_agent", null: false
    t.string "remote_addr", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authenticatable_type", "authenticatable_id"], name: "authenticatable"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
