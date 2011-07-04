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

    if (cart.num_items == 0)
      redirect_to :action => 'index'
    else
      if Address.find_active(current_user.id).nil?
        redirect_to :action => 'new', :controller => 'addresses'
      else
        redirect_to :action => 'check_out'
      end
    end
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
    @addresses = Address.find_active(current_user.id, :order => :first_name)
    
    if @addresses.nil? || @addresses.empty?
      render :action => "new", :controller => "addresses"
      return
    end
    
    # Todo: find most recent address from last order
    @shipping_address = get_address(:shipping_address, @addresses)
    @billing_address = get_address(:billing_address, @addresses)
    @order = Order.new
    @cart = Cart.find_active_by_user_id(current_user.id)
  end

  def add_new_billing_address
    @address = Address.new
    @address.user_id = current_user.id
  end
  
  def add_new_shipping_address
    @address = Address.new
    @address.user_id = current_user.id
  end
  
  def create_new_billing_address
    @billing_address = Address.new(params[:address])
    @billing_address.user_id = current_user.id

    if @billing_address.save
      @addresses = Address.find_active(current_user.id, :order => :first_name)
      @cart = Cart.find_active_by_user_id(current_user.id)
      session[:billing_address] = @billing_address.id

      # Todo: find most recent address from last order
      @shipping_address = get_address(:shipping_address, @addresses)
    
      @order = Order.new
      render :action => "check_out"
    else
      render :action => "add_new_billing_address"
    end    
  end
  
  def create_new_shipping_address
    @shipping_address = Address.new(params[:address])
    @shipping_address.user_id = current_user.id

    if @shipping_address.save
      @addresses = Address.find_active(current_user.id, :order => :first_name)
      @cart = Cart.find_active_by_user_id(current_user.id)
      session[:shipping_address] = @shipping_address.id

      # Todo: find most recent address from last order
      @billing_address = get_address(:billing_address, @addresses)
    
      @order = Order.new
      render :action => "check_out"
    else
      render :action => "add_new_shipping_address"
    end    
  end

  def finalize_check_out
    @cart = Cart.find_active_by_user_id(current_user.id)
    @order = @cart.build_order(params[:order])

    @order.ip_address = request.remote_ip
    @order.billing_address_id = params[:billing_address_id]
    @order.shipping_address_id = params[:shipping_address_id]
    @order.user_id = current_user.id

    if (!@order.save)
      @addresses = Address.find_active(current_user.id, :order => :first_name)
      @shipping_address = get_address(:shipping_address, @addresses)
      @billing_address = get_address(:billing_address, @addresses)

      render 'check_out'
    else
      if @order.purchase
        @cart.mark_ordered
        @cart.save
      else
        @order.destroy # clean up
        @addresses = Address.find_active(current_user.id, :order => :first_name)
        @shipping_address = get_address(:shipping_address, @addresses)
        @billing_address = get_address(:billing_address, @addresses)
        @order = @cart.build_order(params[:order])
        render 'check_out'
      end
    end
  end
  
  def select_new_billing_address
    @addresses = Address.find_active(current_user.id, :order => :first_name)
    @action = "billing"
    render 'select_new_address'
  end
  
  def select_new_shipping_address
    @addresses = Address.find_active(current_user.id, :order => :first_name)
    @action = "shipping"
    render 'select_new_address'
  end
  
  def choose_new_shipping_address
logger.debug "address id is " << params[:address_id].inspect << " OK!"
    session[:shipping_address] = params[:address_id]      
    
    redirect_to :action => 'check_out'
  end

  def choose_new_billing_address
    logger.debug "address id is " << params[:address_id].inspect << " OK!"
    session[:billing_address] = params[:address_id]      
    
    redirect_to :action => 'check_out'
  end
  
  private 
  
  def get_address(address_identifier, addresses)
    if session[address_identifier].blank?
      addresses.first
    else
      return_address = Address.find_by_id_and_user_id(session[address_identifier], current_user.id)
      if (return_address.nil?) # potential bug w/ mult users on same computer
        @addresses.first
      else
        return_address
      end
    end
  end
end
