# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140609215153) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "categories", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "legacy_id"
  end

  create_table "posts", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.uuid     "category_id"
    t.uuid     "user_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "legacy_category_id"
    t.integer  "legacy_id"
    t.integer  "legacy_user_id"
  end

  add_index "posts", ["category_id"], name: "index_posts_on_category_id", using: :btree
  add_index "posts", ["user_id"], name: "index_posts_on_user_id", using: :btree

  create_table "users", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
    t.string   "email"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "legacy_id"
  end

end
