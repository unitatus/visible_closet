VisibleCloset::Application.routes.draw do

  resources :orders
  resources :products

  match "boxes/receive_box" => "boxes#receive_box"
  match "boxes/inventory_box" => "boxes#inventory_box"
  match "boxes/delete_stored_item" => "boxes#delete_stored_item"
  match "boxes/inventory_boxes" => "boxes#inventory_boxes"
  match "boxes/clear_box" => "boxes#clear_box"
  
  resources :boxes

  resources :addresses
  
  resources :stored_items, :only => [:index, :create]

  match "orders/:id/process" => "orders#process_order"
  match "orders/:id/ship_order_lines" => "orders#ship_order_lines"

  devise_for :users, :path_names => { :sign_up => "beta_register" }, :controllers => { :registrations => "registrations" }

  get "home/index"
  get "pages/beta_thanks"
  get "admin/home"
  get "admin/send_boxes"
  get "admin/inventory_boxes"
  get "admin/process_orders"
  post "admin/send_boxes_user_search"
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
  post "boxes/create_stored_item"
  
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
