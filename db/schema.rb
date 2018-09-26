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

ActiveRecord::Schema.define(version: 2018_09_25_225604) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "key_masters", force: :cascade do |t|
    t.string "token", null: false
    t.integer "threshold", default: 10, null: false
    t.integer "period", default: 60, null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "expires_at", default: -> { "(CURRENT_TIMESTAMP + '01:00:00'::interval)" }, null: false
    t.index ["token"], name: "index_key_masters_on_token", unique: true
  end

  create_table "rate_limiters", force: :cascade do |t|
    t.bigint "key_master_id"
    t.datetime "access_time", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["access_time"], name: "index_rate_limiters_on_access_time", order: "DESC NULLS LAST"
    t.index ["key_master_id"], name: "index_rate_limiters_on_key_master_id"
  end

end
