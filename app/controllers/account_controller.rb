class AccountController < ApplicationController
  def index
  end

  def store_more_boxes
    @your_box_uninsured = Product.find(Rails.application.config.your_box_uninsured_product_id)
    @our_box_uninsured = Product.find(Rails.application.config.our_box_uninsured_product_id)
    @your_box_insured = Product.find(Rails.application.config.your_box_insured_product_id)
    @our_box_insured = Product.find(Rails.application.config.our_box_insured_product_id)

    @cart = Cart.find_active_by_user_id(current_user.id)
    @cart = Cart.new unless @cart
  end

  def order_boxes
    cart = Cart.find_active_by_user_id(current_user.id)
    if (cart.nil?)
      cart = Cart.new
      cart.user_id = current_user.id
    end

    convert_params

    if (params[:num_boxes_yours_uninsured] != "0") 
      cart = process_cart_item(cart, 
        Rails.application.config.your_box_uninsured_product_id, 
        params[:num_boxes_yours_uninsured])
    end

    if (params[:num_boxes_ours_uninsured] != "0") 
      cart = process_cart_item(cart, 
        Rails.application.config.our_box_uninsured_product_id, 
        params[:num_boxes_ours_uninsured])
    end

    if (params[:num_boxes_yours_insured] != "0") 
      cart = process_cart_item(cart, 
        Rails.application.config.your_box_insured_product_id, 
        params[:num_boxes_yours_insured])
    end

    if (params[:num_boxes_ours_insured] != "0") 
      cart = process_cart_item(cart, 
        Rails.application.config.our_box_insured_product_id, 
        params[:num_boxes_ours_insured])
    end

    if (cart.save())
      flash[:notice] = "Cart updated. Click the cart option on the left to see cart contents and finalize order."
    else
      flash[:alert] = "There was a problem saving your update to the cart."
    end

    redirect_to :action => 'index'    
  end

  def process_cart_item(cart, product_id, quantity)
    cart_item = cart.cart_items.select { |c| c.product_id == product_id }[0]

    if (!cart_item)
      cart_item = CartItem.new
      cart_item.product_id = product_id
      cart.cart_items << cart_item
    end

    cart_item.quantity = quantity

    cart
  end

  def convert_params()
    if (params[:num_boxes_yours_uninsured].blank?)
      params[:num_boxes_yours_uninsured] = "0"
    end
    
    if (params[:num_boxes_yours_insured].blank?)
      params[:num_boxes_yours_insured] = "0"
    end

    if (params[:num_boxes_ours_uninsured].blank?)
      params[:num_boxes_ours_uninsured] = "0"
    end

    if (params[:num_boxes_ours_insured].blank?)
      params[:num_boxes_ours_insured] = "0"
    end

    params
  end

  def cart
    @cart = Cart.find_active_by_user_id(current_user.id)
    if (@cart.nil?)
      @cart = Cart.new
    end
  end

  def update_cart_item
    if (params[:quantity] == '0')
      remove_cart_item
      return
    end

    cart_item = CartItem.find(params[:cart_item_id])

    cart_item.quantity = params[:quantity]

    if (cart_item.save())
      flash.now[:notice] = "Cart item quantity updated to #{cart_item.quantity}!"
    else
      flash.now[:alert] = "There was a problem saving your update."
      @errors = cart_item.errors
    end

    @cart = Cart.find(cart_item.cart_id)

    render 'cart'
  end

  def remove_cart_item
    # find the cart so we can re-show the page
    cart_item = CartItem.find(params[:cart_item_id])
   
    CartItem.delete(params[:cart_item_id])

    flash.now[:notice] = "Cart item removed."

    @cart = Cart.find(cart_item.cart_id)

    render 'cart'
  end

  def check_out
    @cart = Cart.find_active_by_user_id(current_user.id)
    @billing_address = Address.new
    @shipping_address = Address.new
    @addresses = Address.all(:conditions => {:user_id => current_user.id} )
    @order = Order.new
  end

  # assumption: you cannot update addresses here, only add new ones 
  # or search for old ones
  def finalize_check_out
    manage_address_create

    manage_order_create

    # Or's work in sequence, so with this if check we avoid having lots of 
    # nested if's.
    if (!@billing_address.valid? || !@shipping_address.valid? || !@order.valid? || !@billing_address.save || !@shipping_address.save || !@order.save)
      render 'check_out'
    end

    if @order.purchase
      @cart.mark_ordered
      if !@cart.save
        render 'check_out'
      end
    else
      render 'check_out'
    end

  end

  def manage_order_create
    @order = @cart.build_order(params[:order])

    @order.ip_address = request.remote_ip
    @order.billing_address_id = @billing_address.id
    @order.user_id = current_user.id

    @order.valid?

    # Create order lines for each cart item
    # Create a charge for the total order amount and associate it with the user
    # Use the order to create credit card transaction
    # Save the response as a credit card transaction
    # If the response was not a success, do the logic to say so
    # If the response was a success, create a payment for the user's account, clear out the cart, and render the next page
  end

  def manage_address_create
    # In case this is a refresh
    initialize_checkout_page

    # Don't copy params if they are nil
    if (params[:same_as_billing][:same_as_billing] != "1" && params[:shipping_address_id].blank?)
      copy_params_to_shipping_address
    end

    # Don't copy params if they are nil
    if (params[:billing_address_id].blank?)
      copy_params_to_billing_address
    end

    # We have to call valid? on each object in order for error messages to be generated. Can't rely on next if, b/c first might fail and second won't trigger.
    @billing_address.valid?
    @shipping_address.valid?
  end

  def initialize_checkout_page
    @cart = Cart.find_active_by_user_id(current_user.id)
    @addresses = Address.all(:conditions => {:user_id => current_user.id} )

    if (params[:billing_address_id].blank?)
      @billing_address = Address.new
      @billing_address.user_id = current_user.id
    else
      @billing_address = Address.find(params[:billing_address_id])
    end

    if (params[:same_as_billing][:same_as_billing] == "1")
      @shipping_address = @billing_address
    else 
      if (params[:shipping_address_id].blank?)
        @shipping_address = Address.new
        @shipping_address.user_id = current_user.id
      else
        @shipping_address = Address.find(params[:shipping_address_id])
      end
    end
  end

  def update_checkout_address
    initialize_checkout_page
    @order = Order.new

    if (params[:saved_address_selected] != 'billing' && params[:billing_address_id].blank?)
      copy_params_to_billing_address
    end

    if (params[:saved_address_selected] != 'shipping' && @shipping_address != @billing_address && params[:shipping_address_id].blank?)
      copy_params_to_shipping_address
    end

    render 'check_out'
  end

  def copy_params_to_shipping_address
    @shipping_address.address_name = params[:shipping_address_name]
    @shipping_address.first_name = params[:shipping_first_name]
    @shipping_address.last_name = params[:shipping_last_name]
    @shipping_address.day_phone = gsub_nullable(params[:shipping_day_phone], /\D/, "")
    @shipping_address.evening_phone = gsub_nullable(params[:shipping_evening_phone], /\D/, "")
    @shipping_address.address_line_1 = params[:shipping_address_line_1]
    @shipping_address.address_line_2 = params[:shipping_address_line_2]
    @shipping_address.city = params[:shipping_city]
    @shipping_address.state = params[:shipping_state]
    @shipping_address.zip = params[:shipping_zip]
  end

  def copy_params_to_billing_address
    @billing_address.address_name = params[:billing_address_name]
    @billing_address.first_name = params[:billing_first_name]
    @billing_address.last_name = params[:billing_last_name]
    @billing_address.day_phone = params[:billing_day_phone].gsub(/\D/, "")
    @billing_address.evening_phone = params[:billing_evening_phone].gsub(/\D/, "")
    @billing_address.address_line_1 = params[:billing_address_line_1]
    @billing_address.address_line_2 = params[:billing_address_line_2]
    @billing_address.city = params[:billing_city]
    @billing_address.state = params[:billing_state]
    @billing_address.zip = params[:billing_zip]
  end

  def gsub_nullable(str, expr, replace)
    if (str.nil?)
      str
    else
      str.gsub(expr, replace)
    end
  end
end
