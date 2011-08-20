VisibleCloset::Application.routes.draw do

  resources :orders
  resources :products

  match "/register" => "pages#register_block"
  match "/register_interest" => "pages#register_interest"
  match "boxes/receive_box" => "boxes#receive_box"
  match "boxes/inventory_box" => "boxes#inventory_box"
  match "boxes/delete_stored_item" => "boxes#delete_stored_item"
  match "boxes/inventory_boxes" => "boxes#inventory_boxes"
  match "boxes/clear_box" => "boxes#clear_box"
  match "boxes/add_tags" => "boxes#add_tags"
  match "boxes/add_tag" => "boxes#add_tag"
  match "boxes/delete_tag" => "boxes#delete_tag"
  match "boxes/finish_inventorying_box" => "boxes#finish_inventorying"
  match "payment_profiles/:id/set_default" => "payment_profiles#set_default"
  match "addresses/:id/set_default_shipping" => "addresses#set_default_shipping"
  match "m" => "pages#marketing_hit"
    
  resources :boxes
  resources :addresses
  resources :payment_profiles
  resources :rental_agreement_versions
  
  match "orders/:id/process" => "orders#process_order"
  match "orders/:id/ship_order_lines" => "orders#ship_order_lines"
  match "boxes/:box_id/stored_items" => "stored_items#index"
  match "/stored_items" => "stored_items#index"
  match "box/:id/get_label" => "boxes#get_label"
  match "shipment/:id/get_label" => "shipments#get_label"
  match "stored_item_tags/:id/delete" => "stored_item_tags#delete"
  match "stored_item_tags/add_tag" => "stored_item_tags#add_tag"

  # Devise stuff
  devise_for :users, :path_names => { :sign_up => "register" }, :controllers => { :registrations => "registrations" }
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
  post "admin/send_boxes_user_search"
  get "admin/users"
  match "admin/user/:id/addresses" => "admin#user_addresses"
  match "admin/user/:id" => "admin#user"
  match "admin/user/:id/orders" => "admin#user_orders"
  match "admin/user/:user_id/order/:order_id/destroy" => "admin#delete_user_order"
  match "admin/shipment/:id/destroy" => "admin#delete_shipment"
  match "admin/user/:id/shipments" => "admin#user_shipments"
  match "admin/user/:id/shipment/:shipment_id/destroy" => "admin#delete_user_shipment"
  match "admin/shipment/:id" => "admin#shipment"
  match "admin/shipment/:id/refresh_fedex_events" => "admin#refresh_shipment_events"
  
  # Account
  get "account/store_more_boxes"
  post "account/order_boxes"
  get "account/cart"
  post "account/update_cart_item"
  get "account/remove_cart_item"
  get "account/check_out"
  post "account/finalize_check_out"
  post "account/update_checkout_address"
  get "account/add_new_billing_address"
  post "account/create_new_billing_address"
  get "account/add_new_shipping_address"
  post "account/create_new_shipping_address"
  get "account/select_new_billing_address"
  get "account/select_new_shipping_address"
  post "account/choose_new_shipping_address"
  post "account/choose_new_billing_address"
  match "orders/:id/print_invoice" => "orders#print_invoice"
  
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
