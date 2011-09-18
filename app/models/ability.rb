class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

    role = user ? user.role : nil
    
    if role == User::ADMIN
      can :manage, :all
      # Note: product management is only handled by administrators
    end
    
    if role == User::MANAGER || role == User::ADMIN
      can :home, :admin
      can :send_boxes, :admin
      can :process_orders, :admin
      can :users, :admin
      can :user_orders, :admin
      can :user_order, :admin
      can :new_user_address, :admin
      can :create_user_address, :admin
      can :shipping, :admin
      can :user_shipments, :admin
      can :set_shipment_charge, :admin
      can :shipment, :admin
      can :user, :admin
      can :user_boxes, :admin
      can :user_box, :admin
      can :user_billing, :admin
      can :user_subscription, :admin
      can :receive_box, Box
      can :inventory_box, Box
      can :inventory_boxes, Box
      can :create_stored_item, Box
      can :delete_stored_item, Box
      can :clear_box, Box
      can :add_tags, Box
      can :add_tag, Box
      can :delete_tag, Box
      can :finish_inventorying, Box
      can :process_order, Order
      can :ship_order_lines, Order
      can :show_invoice, Order
      can :get_order_label, Shipment
    end
    
    if role == User::NORMAL || role == User::ADMIN || role == User::MANAGER
      # account
      can :index, :account
      can :store_more_boxes, :account
      can :order_boxes, :account
      can :cart, :account
      can :update_cart_item, :account
      can :remove_cart_item, :account
      can :check_out, :account
      can :add_new_billing_address, :account
      can :add_new_shipping_address, :account
      can :create_new_billing_address, :account
      can :create_new_shipping_address, :account
      can :finalize_check_out, :account
      can :select_new_billing_address, :account
      can :select_new_shipping_address, :account
      can :choose_new_shipping_address, :account
      can :choose_new_billing_address, :account
      can :closet_main, :account
      can :email_confirmation, :account
      can :external_addresses_validate, :account
      can :new_default_shipping_address, Address
      can :set_default_shipping_address, Address
      can :confirm_new_default_shipping_address, Address
      can :confirm_new_checkout_shipping_address, Address
      can :confirm_address, Address
      can :new_checkout_shipping_address, Address
      can :set_checkout_shipping_address, Address
      can :update_new_checkout_shipping_address, Address
      can :override_fedex, Address
      can :new_default_payment_profile, PaymentProfile
      can :create_default_payment_profile, PaymentProfile
      can :confirm_new_default_shipping_address, Address
      can :confirm_address, Address
      can :print_invoice, Order
      
      # boxes
      can :index, Box
      can :edit, Box
      can :update, Box
      can :get_label, Box
      can :request_box_return, Box
      can :cancel_box_return_request, Box
      
      # stored items
      can :index, StoredItem
      can :user_delete_tag, Box # This is sitting on the boxes controller
      can :user_add_tag, Box 
      can :view, StoredItem
      
      # payment profiles
      can :index, PaymentProfile
      can :new, PaymentProfile
      can :create, PaymentProfile
      can :set_default, PaymentProfile
      can :destroy, PaymentProfile
      
      # addresses
      can :index, Address
      can :new, Address
      can :edit, Address
      can :create, Address
      can :update, Address
      can :set_default_shipping, Address
      can :destroy, Address
      
      # rental agreements
      can :latest_agreement_ajax, :rental_agreement_version
    end
  end
end
