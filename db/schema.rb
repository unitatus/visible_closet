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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110824175202) do

  create_table "addresses", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "day_phone"
    t.string   "evening_phone"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "address_name"
    t.integer  "user_id"
    t.string   "country"
    t.string   "status"
    t.string   "comment"
    t.string   "fedex_validation_status"
  end

  create_table "boxes", :force => true do |t|
    t.integer  "assigned_to_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ordering_order_line_id"
    t.string   "status"
    t.string   "box_type"
    t.text     "description"
    t.string   "indexing_status"
    t.integer  "indexing_order_line_id"
    t.datetime "received_at"
    t.float    "height"
    t.float    "width"
    t.float    "length"
    t.float    "weight"
    t.integer  "box_num"
    t.integer  "subscription_id"
  end

  add_index "boxes", ["assigned_to_user_id"], :name => "index_boxes_on_assigned_to_user_id"
  add_index "boxes", ["ordering_order_line_id"], :name => "index_boxes_on_order_line_id"

  create_table "cart_items", :force => true do |t|
    t.integer  "quantity"
    t.integer  "cart_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "committed_months"
  end

  add_index "cart_items", ["cart_id"], :name => "index_cart_items_on_cart_id"
  add_index "cart_items", ["product_id"], :name => "index_cart_items_on_product_id"

  create_table "carts", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "ordered_at"
    t.string   "status"
  end

  add_index "carts", ["user_id"], :name => "index_carts_on_user_id"

  create_table "charges", :force => true do |t|
    t.integer  "user_id"
    t.integer  "total_in_cents"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
    t.integer  "shipment_id"
  end

  add_index "charges", ["shipment_id"], :name => "index_charges_on_shipment_id"

  create_table "interested_people", :force => true do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invoices", :force => true do |t|
    t.integer  "user_id"
    t.integer  "payment_transaction_id"
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "marketing_hits", :force => true do |t|
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_lines", :force => true do |t|
    t.integer  "order_id"
    t.integer  "product_id"
    t.integer  "quantity"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "committed_months"
  end

  add_index "order_lines", ["order_id"], :name => "index_order_lines_on_order_id"
  add_index "order_lines", ["product_id"], :name => "index_order_lines_on_product_id"

  create_table "orders", :force => true do |t|
    t.integer  "cart_id"
    t.string   "ip_address"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "shipping_address_id"
  end

  add_index "orders", ["cart_id"], :name => "index_orders_on_cart_id"
  add_index "orders", ["user_id"], :name => "index_orders_on_user_id"

  create_table "payment_profiles", :force => true do |t|
    t.string   "identifier"
    t.string   "last_four_digits"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "year"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "billing_address_id"
    t.string   "cc_type"
    t.string   "month"
    t.boolean  "active"
  end

  add_index "payment_profiles", ["user_id"], :name => "index_payment_profiles_on_user_id"

  create_table "payment_transactions", :force => true do |t|
    t.integer  "order_id"
    t.string   "action"
    t.float    "amount"
    t.boolean  "success"
    t.string   "authorization"
    t.string   "message"
    t.text     "params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "payment_profile_id"
  end

  add_index "payment_transactions", ["order_id"], :name => "index_payment_transactions_on_order_id"
  add_index "payment_transactions", ["user_id"], :name => "index_payment_transactions_on_user_id"

  create_table "photos", :force => true do |t|
    t.integer  "stored_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.datetime "data_updated_at"
  end

  add_index "photos", ["stored_item_id"], :name => "index_photos_on_stored_item_id"

  create_table "products", :force => true do |t|
    t.string   "name"
    t.float    "price"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "price_comment"
    t.string   "first_due"
  end

  create_table "rental_agreement_versions", :force => true do |t|
    t.text     "agreement_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rental_agreement_versions_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "rental_agreement_version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rental_agreement_versions_users", ["rental_agreement_version_id"], :name => "users_rav_rav_index"
  add_index "rental_agreement_versions_users", ["user_id"], :name => "users_rav_user_index"

  create_table "shipments", :force => true do |t|
    t.integer  "box_id"
    t.integer  "from_address_id"
    t.integer  "to_address_id"
    t.string   "tracking_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "shipment_label_file_name"
    t.datetime "shipment_label_updated_at"
    t.string   "state"
    t.integer  "order_id"
    t.string   "payor"
  end

  add_index "shipments", ["box_id"], :name => "index_shipments_on_box_id"
  add_index "shipments", ["from_address_id"], :name => "index_shipments_on_from_address_id"
  add_index "shipments", ["to_address_id"], :name => "index_shipments_on_to_address_id"
  add_index "shipments", ["tracking_number"], :name => "index_shipments_on_tracking_number"

  create_table "stored_item_tags", :force => true do |t|
    t.integer  "stored_item_id"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stored_items", :force => true do |t|
    t.integer  "box_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "access_token"
  end

  add_index "stored_items", ["box_id"], :name => "index_stored_items_on_box_id"

  create_table "subscriptions", :force => true do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "user_id"
    t.integer  "duration_in_months"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                      :default => "",   :null => false
    t.string   "encrypted_password",          :limit => 128, :default => "",   :null => false
    t.string   "reset_password_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                              :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "password_salt"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                            :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.string   "authentication_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "last_name"
    t.string   "first_name"
    t.boolean  "beta_user",                                  :default => true
    t.text     "signup_comments"
    t.string   "role"
    t.string   "cim_id"
    t.integer  "default_payment_profile_id"
    t.integer  "default_shipping_address_id"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
