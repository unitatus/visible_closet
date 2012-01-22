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

ActiveRecord::Schema.define(:version => 20120122173933) do

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

  add_index "addresses", ["user_id"], :name => "index_addresses_on_user_id"

  create_table "boxes", :force => true do |t|
    t.integer  "assigned_to_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ordering_order_line_id"
    t.string   "status"
    t.string   "box_type"
    t.string   "inventorying_status"
    t.integer  "inventorying_order_line_id"
    t.datetime "received_at"
    t.float    "weight"
    t.integer  "box_num"
    t.datetime "return_requested_at"
    t.datetime "inventoried_at"
    t.integer  "created_by_id"
  end

  add_index "boxes", ["assigned_to_user_id"], :name => "index_boxes_on_assigned_to_user_id"
  add_index "boxes", ["inventorying_order_line_id"], :name => "index_boxes_on_inventorying_order_line_id"
  add_index "boxes", ["ordering_order_line_id"], :name => "index_boxes_on_order_line_id"

  create_table "cart_items", :force => true do |t|
    t.integer  "quantity"
    t.integer  "cart_id"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "committed_months"
    t.integer  "box_id"
    t.integer  "address_id"
    t.integer  "stored_item_id"
  end

  add_index "cart_items", ["cart_id"], :name => "index_cart_items_on_cart_id"
  add_index "cart_items", ["product_id"], :name => "index_cart_items_on_product_id"

  create_table "carts", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "ordered_at"
    t.string   "status"
    t.float    "quoted_shipping_cost"
    t.boolean  "quoted_shipping_cost_success"
  end

  add_index "carts", ["user_id"], :name => "index_carts_on_user_id"

  create_table "chargeable_unit_properties", :force => true do |t|
    t.float   "height"
    t.float   "width"
    t.float   "length"
    t.string  "location"
    t.integer "chargeable_unit_id"
    t.string  "chargeable_unit_type"
    t.string  "description"
  end

  create_table "charges", :force => true do |t|
    t.integer  "user_id"
    t.float    "total_in_cents"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
    t.integer  "shipment_id"
    t.string   "comments"
    t.integer  "created_by_admin_id"
  end

  add_index "charges", ["order_id"], :name => "index_charges_on_order_id"
  add_index "charges", ["user_id"], :name => "index_charges_on_user_id"

  create_table "coupons", :force => true do |t|
    t.integer "assigned_to_user_id"
    t.string  "unique_identifier"
    t.integer "offer_id"
    t.string  "offer_type"
  end

  add_index "coupons", ["unique_identifier"], :name => "index_coupons_on_unique_identifier"

  create_table "credits", :force => true do |t|
    t.float    "amount"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.integer  "created_by_admin_id"
  end

  create_table "free_storage_benefit_properties", :force => true do |t|
    t.integer "free_storage_offer_benefit_id"
    t.integer "num_boxes"
    t.integer "num_months"
  end

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

  add_index "invoices", ["order_id"], :name => "index_invoices_on_order_id"

  create_table "marketing_hits", :force => true do |t|
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "offer_benefits", :force => true do |t|
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "offer_id"
  end

  create_table "offers", :force => true do |t|
    t.string   "unique_identifier"
    t.datetime "start_date"
    t.datetime "expiration_date"
    t.integer  "created_by_user_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active"
  end

  add_index "offers", ["unique_identifier"], :name => "index_offers_on_unique_identifier"

  create_table "order_lines", :force => true do |t|
    t.integer  "order_id"
    t.integer  "product_id"
    t.integer  "quantity"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "committed_months"
    t.integer  "shipping_address_id"
    t.integer  "service_box_id"
    t.integer  "shipment_id"
    t.integer  "service_item_id"
    t.integer  "item_mail_shipping_charge_id"
    t.float    "amount_paid_at_purchase"
  end

  add_index "order_lines", ["order_id"], :name => "index_order_lines_on_order_id"
  add_index "order_lines", ["product_id"], :name => "index_order_lines_on_product_id"

  create_table "orders", :force => true do |t|
    t.integer  "cart_id"
    t.string   "ip_address"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "initial_charged_shipping_cost"
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
    t.string   "authorization"
    t.string   "message"
    t.text     "params"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "payment_profile_id"
    t.string   "status"
    t.integer  "storage_payment_processing_record_id"
    t.string   "auth_transaction_id"
    t.integer  "credit_id"
    t.float    "submitted_amount"
  end

  add_index "payment_transactions", ["order_id"], :name => "index_payment_transactions_on_order_id"
  add_index "payment_transactions", ["storage_payment_processing_record_id"], :name => "payment_transaction_spprid"
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
    t.boolean  "discountable"
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
    t.string   "payor"
    t.boolean  "charge_requested"
  end

  add_index "shipments", ["box_id"], :name => "index_shipments_on_box_id"
  add_index "shipments", ["from_address_id"], :name => "index_shipments_on_from_address_id"
  add_index "shipments", ["to_address_id"], :name => "index_shipments_on_to_address_id"
  add_index "shipments", ["tracking_number"], :name => "index_shipments_on_tracking_number"

  create_table "storage_charge_processing_records", :force => true do |t|
    t.integer  "generated_by_user_id"
    t.datetime "as_of_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "locked_for_editing"
  end

  create_table "storage_charges", :force => true do |t|
    t.integer  "charge_id"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "storage_charge_processing_record_id"
    t.integer  "chargeable_unit_properties_id"
  end

  add_index "storage_charges", ["charge_id"], :name => "index_storage_charges_on_charge_id"
  add_index "storage_charges", ["storage_charge_processing_record_id"], :name => "index_storage_charges_on_stor_chg_proc_rec_id"

  create_table "storage_payment_processing_records", :force => true do |t|
    t.integer  "generated_by_user_id"
    t.datetime "as_of_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stored_item_photos", :force => true do |t|
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "access_token"
    t.integer  "stored_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "visibility"
  end

  create_table "stored_item_tags", :force => true do |t|
    t.integer  "stored_item_id"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stored_item_tags", ["stored_item_id"], :name => "index_stored_item_tags_on_stored_item_id"

  create_table "stored_items", :force => true do |t|
    t.integer  "box_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.string   "donated_to"
    t.integer  "shipment_id"
    t.string   "type"
    t.integer  "creator_id"
    t.integer  "user_id"
    t.integer  "default_customer_stored_item_photo_id"
    t.integer  "default_admin_stored_item_photo_id"
  end

  add_index "stored_items", ["box_id"], :name => "index_stored_items_on_box_id"

  create_table "subscriptions", :force => true do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "user_id"
    t.integer  "duration_in_months"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "chargeable_unit_properties_id"
  end

  add_index "subscriptions", ["user_id"], :name => "index_subscriptions_on_user_id"

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
    t.boolean  "test_user"
    t.integer  "acting_as_user_id"
    t.boolean  "first_time_signed_up"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
