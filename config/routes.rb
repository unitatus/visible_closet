VisibleCloset::Application.routes.draw do

  resources :orders
  resources :products
  resources :storage_charge_processing_records
  resources :storage_payment_processing_records

  match "/register" => "pages#register_block"
  match "/register_interest" => "pages#register_interest"
  match "boxes/receive_box" => "boxes#receive_box"
  match "boxes/inventory_box" => "boxes#inventory_box"
  match "boxes/delete_stored_item" => "boxes#delete_stored_item"
  match "boxes/inventory_boxes" => "boxes#inventory_boxes"
  match "boxes/clear_box" => "boxes#clear_box"
  match "boxes/add_tags" => "boxes#add_tags"
  match "boxes/add_tag" => "boxes#add_tag"
  match "boxes/user_add_tag" => "boxes#user_add_tag"
  match "boxes/delete_tag" => "boxes#delete_tag"
  match "boxes/user_delete_tag" => "boxes#user_delete_tag"
  match "boxes/:id/request_box_return" => "boxes#request_box_return"
  match "boxes/:id/cancel_box_return_request" => "boxes#cancel_box_return_request"
  match "boxes/finish_inventorying_box" => "boxes#finish_inventorying"
  get "stored_items/autocomplete_stored_item_tags"
  match "stored_items/:id" => "stored_items#view"
  
  match "payment_profiles/:id/set_default" => "payment_profiles#set_default"
  match "addresses/:id/set_default_shipping" => "addresses#set_default_shipping"
  match "m" => "pages#marketing_hit"
  get "addresses/new_default_shipping_address"
  post "addresses/set_default_shipping_address"
  match "addresses/:id/update_default_shipping_address" => "addresses#set_default_shipping_address"
  match "addresses/:id/override_fedex" => "addresses#override_fedex"
  get "addresses/confirm_new_default_shipping_address"
  get "addresses/confirm_address"
  match "addresses/:id/confirm_address" => "addresses#confirm_address"
  get "payment_profiles/new_default_payment_profile"
  post "payment_profiles/create_default_payment_profile"
  post "addresses/admin_fedex_override"
  # these paths exist so as to avoid confusing the user -- we want address processing in one controller (addresses), but this address maintenance only happens
  # during checkout, when everything is account/
  match "account/set_checkout_shipping_address" => "addresses#set_checkout_shipping_address"
  match "account/new_checkout_shipping_address" => "addresses#new_checkout_shipping_address"
  match "/account/update_new_checkout_shipping_address/:id" => "addresses#update_new_checkout_shipping_address"
  
  # Stored Item Services
  match "stored_items/:id/request_donation" => "stored_items#request_charitable_donation"
  match "stored_items/:id/cancel_donation_request" => "stored_items#cancel_donation_request"
  match "stored_items/:id/request_mailing" => "stored_items#request_mailing"
  match "stored_items/:id/cancel_mailing_request" => "stored_items#cancel_mailing_request"
  match "stored_items/:id/cancel_retrieval_request" => "stored_items#cancel_retrieval_request"
  match "stored_items/:id/request_retrieval" => "stored_items#request_retrieval"
  match "/stored_items" => "stored_items#index"
  match "/furniture_items" => "furniture_items#index"
  match "/furniture_items/:id" => "furniture_items#view"
  match "furniture_items/:id/save_description" => "furniture_items#save_description"
  
  resources :boxes
  resources :addresses
  resources :payment_profiles
  resources :rental_agreement_versions
  
  match "orders/:id/process" => "orders#process_order"
  match "orders/:id/process_item_mailing_order_lines" => "orders#process_item_mailing_order_lines"
  match "orders/:id/ship_item_mailing_order_lines" => "orders#ship_item_mailing_order_lines"
  match "orders/:id/price_item_mailing_order_lines" => "orders#price_item_mailing_order_lines"
  match "orders/:id/add_shipping_charge" => "orders#add_shipping_charge"
  match "orders/:id/ship_order_lines" => "orders#ship_order_lines"
  match "order_lines/:id/cancel" => "orders#cancel_order_line"
  match "boxes/:box_id/stored_items" => "stored_items#index"
  match "boxes/:id/request_inventory" => "boxes#request_inventory"
  match "box/:id/get_label" => "boxes#get_label"
  match "shipment/:id/get_label" => "shipments#get_label"
  match "stored_item_tags/:id/delete" => "stored_item_tags#delete"
  match "stored_item_tags/add_tag" => "stored_item_tags#add_tag"

  # Devise stuff
  devise_for :users, :path_names => { :sign_up => "register" }, \
    :controllers => { :registrations => "registrations", :confirmations => "confirmations", :sessions => "sessions", :passwords => "passwords" }
  # this redirects users after logging in to their account home
  match '/user' => "account#index", :as => :user_root

  # Home and Pages
  get "home/index"
  match "access_denied" => "home#access_denied"
  match "how_it_works" => "pages#how_it_works"
  match "restrictions" => "pages#restrictions"
  match "contact" => "pages#contact"
  match "pages/contact_post" => "pages#contact_post"
  match "pages/support_post" => "pages#support_post"
  match "packing_tips" => "pages#packing_tips"
  match "right_for_me" => "pages#right_for_me"
  match "faq" => "pages#faq"
  match "legal" => "pages#legal"
  match "pricing" => "pages#pricing"
  match "privacy" => "pages#privacy"
  match "support" => "pages#support"
  match "member_agreement_ajax" => "rental_agreement_versions#latest_agreement_ajax"
  match "member_agreement" => "rental_agreement_versions#latest_agreement"
  get "pages/fedex_unavailable"
  get "pages/request_confirmation"
  match "pages/test_validate_address" => "pages#test_validate_address"
  
  # Admin
  match "admin/home" => "admin#process_orders"
  get "admin/shipping"
  get "admin/inventory_boxes"
  get "admin/process_orders"
  get "admin/monthly_charges"
  post "admin/send_boxes_user_search"
  post "admin/generate_charges"
  get "admin/users"
  match "admin/user/:id/addresses" => "admin#user_addresses"
  match "admin/user/:id/switch_test_user_status" => "admin#switch_test_user_status"
  match "admin/user/:id" => "admin#user"
  match "admin/user/:id/clear_test_data" => "admin#clear_user_data"
  match "admin/user/:id/destroy" => "admin#destroy_user"
  match "admin/user/:id/orders" => "admin#user_orders"
  match "admin/user/:user_id/order/:order_id/destroy" => "admin#delete_user_order"
  match "admin/users/:id/create_customer_boxes" => "boxes#create_customer_boxes"
  match "admin/users/:id/add_customer_boxes" => "boxes#add_customer_boxes"
  match "admin/users/:id/furniture" => "furniture_items#admin_index"
  match "admin/users/:id/add_furniture_item" => "furniture_items#admin_add"
  match "admin/users/:id/create_furniture_item" => "furniture_items#admin_create"
  match "admin/shipment/:id/destroy" => "admin#delete_shipment"
  match "admin/user/:id/shipments" => "admin#user_shipments"
  match "admin/user/:id/shipment/:shipment_id/destroy" => "admin#delete_user_shipment"
  match "admin/shipment/:id" => "admin#shipment"
  match "admin/shipment/:id/refresh_fedex_events" => "admin#refresh_shipment_events"
  match "admin/shipment/:id/set_charge" => "admin#set_shipment_charge"
  match "admin/user/:user_id/new_address" => "addresses#admin_new_address"
  match "admin/user/:user_id/create_address/:id" => "addresses#admin_create_address"
  match "admin/user/:user_id/create_address" => "addresses#admin_create_address"
  match "admin/user/:user_id/confirm_address" => "addresses#admin_confirm_address"
  match "admin/double_post"
  match "admin/user/:id/boxes" => "admin#user_boxes"
  match "admin/user/:user_id/boxes/:box_id/destroy" => "admin#delete_user_box"
  match "admin/user/:user_id/boxes/:box_id" => "admin#user_box"
  match "admin/user/:user_id/orders/:order_id" => "admin#user_order"
  match "admin/user/:id/billing" => "admin#user_billing"
  match "admin/invoices/:id" => "orders#show_invoice"
  match "admin/user/:user_id/subscriptions/:subscription_id" => "admin#user_subscription"
  match "admin/charges/:id/delete" => "admin#delete_charge"
  match "admin/generate_payments" => "admin#generate_payments"
  match "admin/user_account_balances" => "admin#user_account_balances"
  match "admin/impersonate_user/:id" => "admin#impersonate_user"
  match "admin/stop_impersonating" => "admin#stop_impersonating"
  match "admin/users/:id/add_charge" => "admin#add_user_charge"
  match "admin/billing/charges/:id/destroy" => "admin#destroy_billing_charge"
  match "admin/users/:id/add_credit" => "admin#add_user_credit"
  match "admin/billing/credits/:id/destroy" => "admin#destroy_billing_credit"
  
  # Marketing
  resources :offers
  match "offers/:id/activate" => "offers#activate"
  match "offers/:id/add_coupons" => "offers#add_coupons"
  match "coupons/:id/delete" => "offers#destroy_coupon"

  # Furniture
  match "admin/furniture_items/:id/photos" => "furniture_items#admin_manage_photos"
  match "admin/furniture_items/:id/create_photo" => "furniture_items#admin_create_photo"
  match "admin/furniture_items/:id/edit" => "furniture_items#admin_edit"
  match "admin/furniture_items/:id/save" => "furniture_items#admin_save"
  match "admin/furniture_items/:id/destroy" => "furniture_items#admin_destroy_furniture_item"
  match "admin/furniture_items/:furniture_item_id/photos/:photo_id/destroy" => "furniture_items#admin_destroy_photo"
  match "admin/furniture_items/:id/publish" => "furniture_items#admin_publish_furniture_item"
  match "admin/furniture_items/:id/unpublish" => "furniture_items#admin_unpublish_furniture_item"
  match "admin/furniture_items/:furniture_item_id/photos/:photo_id/save" => "furniture_items#save_photo"
  match "admin/furniture_items/:id" => "furniture_items#admin_view"
  
  # Account
  get "account/store_more_boxes"
  post "account/order_boxes"
  get "account/cart"
  post "account/update_cart_item"
  get "account/remove_cart_item"
  get "account/check_out"
  post "account/check_out" # for overriding fedex address suggestions when changing shipping address during checkout
  get "account/check_out_remove_cart_item"
  post "account/finalize_check_out"
  post "account/update_checkout_address"
  get "account/add_new_billing_address"
  post "account/create_new_billing_address"
  get "account/add_new_shipping_address"
  match "account/create_new_shipping_address" => "addresses#create_new_shipping_address"
  get "account/select_new_billing_address"
  get "account/select_new_shipping_address"
  post "account/choose_new_shipping_address"
  post "account/choose_new_billing_address"
  get "account/invoice_estimate"
  match "account/history" => "account#account_history"
  match "orders/:id/print_invoice" => "orders#print_invoice"
  get "account/external_addresses_validate"
  
  post "boxes/create_stored_item"
  get "account/closet_main"
  get "fedex_test/test"
  
  match "account/home" => "account#index"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "home#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
