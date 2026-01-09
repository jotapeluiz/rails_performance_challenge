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

ActiveRecord::Schema.define(version: 20260109190133) do

  create_table "orders", force: :cascade do |t|
    t.integer  "product_id",       limit: 4
    t.string   "customer_email",   limit: 255
    t.string   "customer_name",    limit: 255
    t.string   "status",           limit: 255
    t.decimal  "total_amount",                   precision: 10, scale: 2
    t.integer  "quantity",         limit: 4
    t.date     "order_date"
    t.string   "shipping_address", limit: 255
    t.string   "city",             limit: 255
    t.string   "state",            limit: 255
    t.string   "zip_code",         limit: 255
    t.string   "country",          limit: 255
    t.text     "notes",            limit: 65535
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
  end

  add_index "orders", ["customer_email"], name: "index_orders_on_customer_email", using: :btree
  add_index "orders", ["order_date"], name: "index_orders_on_order_date", using: :btree

  create_table "products", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "sku",         limit: 255
    t.decimal  "price",                     precision: 10, scale: 2
    t.string   "category",    limit: 255
    t.text     "description", limit: 65535
    t.boolean  "active",                                             default: true
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
  end

end
