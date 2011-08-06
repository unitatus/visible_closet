class AccountController < ApplicationController
  # The account controller actions are only accessible for someone who is signed up as a user.
  authorize_resource :class => false

  before_filter :set_menu

  def ssl_required?
    true
  end

  def index

  end

  def store_more_boxes
    @your_box = Product.find(Rails.application.config.your_box_product_id)
    @our_box = Product.find(Rails.application.config.our_box_product_id)

    @cart = Cart.find_active_by_user_id(current_user.id)
    @cart = Cart.new unless @cart
  end

  def order_boxes
    @cart = Cart.find_active_by_user_id(current_user.id)
    if (@cart.nil?)
      @cart = Cart.new
      @cart.user_id = current_user.id
    end
    
    process_cart_item(@cart, Rails.application.config.your_box_product_id, params[:num_boxes_yours])
    process_cart_item(@cart, Rails.application.config.our_box_product_id, params[:num_boxes_ours])

    if (@cart.save())
      flash[:notice] = "Cart updated. Click the cart option on the left to see cart contents and finalize order."
    else
      flash[:alert] = "There was a problem saving your update to the cart."
      @your_box = Product.find(Rails.application.config.your_box_product_id)
      @our_box = Product.find(Rails.application.config.our_box_product_id)
      render :store_more_boxes
      return
    end

    if @cart.cart_items.size == 0
      @your_box = Product.find(Rails.application.config.your_box_product_id)
      @our_box = Product.find(Rails.application.config.our_box_product_id)
      @cart.errors[:cart] = "Please enter at least one positive integer."
      render :store_more_boxes
    else
      if Address.find_active(current_user.id).nil?
        redirect_to :action => 'new', :controller => 'addresses'
      else
        redirect_to :action => 'check_out'
      end
    end
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
    
    if !@cart || @cart.cart_items.empty?
      redirect_to :action => :store_more_boxes
      return
    end
    
    @addresses = Address.find_active(current_user.id, :order => :first_name)
    
    if @addresses.nil? || @addresses.empty?
      @address = Address.new
      render :action => "add_new_shipping_address"
      return
    end
    
    if current_user.default_payment_profile.nil?
      redirect_to "/payment_profiles/new?source_c=account&source_a=check_out" and return
    end
    
    @shipping_address = get_address_from_session(:shipping_address)
    if (@shipping_address.nil?)
      @shipping_address = get_last_shipping_address @addresses
    end
    
    @order = Order.new
  end

  def add_new_shipping_address
    @address = Address.new
    @address.user_id = current_user.id
  end
    
  def create_new_shipping_address
    @shipping_address = Address.new(params[:address])
    @shipping_address.user_id = current_user.id

    if @shipping_address.save
      @addresses = Address.find_active(current_user.id, :order => :first_name)
      @cart = Cart.find_active_by_user_id(current_user.id)
      session[:shipping_address] = @shipping_address.id
          
      @order = Order.new
      redirect_to "/account/check_out"
    else
      render :action => "add_new_shipping_address"
    end    
  end

  def finalize_check_out
    @cart = Cart.find_active_by_user_id(current_user.id)
    
    # The most likely reason why a cart would not be found is because the submit button was clicked twice, and the order previously committed.
    # That means we should render nicely as though it did.
    if (!@cart)
      @order = Order.find_all_by_user_id(current_user.id, :first, :order => 'created_at DESC').first
      return
    end
    
    @order = @cart.build_order_properly(params[:order])

    @order.ip_address = request.remote_ip
    @order.shipping_address_id = params[:shipping_address_id]
    @order.user_id = current_user.id
    
    # the only way to get to this function is if the user saw the member agreement; take note of that
    if params[:agreed] == "1"
      current_agreement = RentalAgreementVersion.latest
      user = current_user
      if !user.rental_agreement_versions.include? current_agreement
        user.rental_agreement_versions << current_agreement
      end
    else
      @order.errors.add(:agreement, "You must agree to the rental agreement to proceed.")
      fail_checkout
      return
    end
    
    if (!@order.purchase)
      fail_checkout
    end
    
    @cart = nil
  end
  
  def fail_checkout
    @addresses = Address.find_active(current_user.id, :order => :first_name)
    @shipping_address = get_address_from_session(:shipping_address)
    if (@shipping_address.nil?)
      @shipping_address = get_last_shipping_address @addresses
    end

    render 'check_out'    
  end
  
  def select_new_shipping_address
    @addresses = Address.find_active(current_user.id, :order => :first_name)
    @action = "shipping"
    render 'select_new_address'
  end
  
  def choose_new_shipping_address
    session[:shipping_address] = params[:address_id]      
    
    redirect_to :action => 'check_out'
  end
  
  def closet_main
    
  end
  
  private 
  
  def set_menu
    @top_menu_page = :account
  end
  
  def process_cart_item(cart, product_id, quantity)
    cart_item = cart.cart_items.select { |c| c.product_id == product_id }[0]

    if (!cart_item && quantity.to_i != 0)
      cart_item = CartItem.new
      cart_item.product_id = product_id
      cart.cart_items << cart_item
    elsif cart_item && quantity.to_i == 0
      cart.cart_items.delete(cart_item)
    end

    cart_item.quantity = quantity unless cart_item.nil?
  end
  
  def get_address_from_session(address_identifier)
    if session[address_identifier].blank?
      nil
    else
      return_address = Address.find_active_by_id_and_user_id(session[address_identifier], current_user.id)
      if (return_address.nil?) # potential bug w/ mult users on same computer
        @addresses.first
      else
        return_address
      end
    end
  end
  
  def get_last_shipping_address(user_id=nil, addresses)
    last_order = get_last_order(user_id, "shipping_address_id")
    if last_order
      last_order.shipping_address
    else
      shipping_address = current_user.default_shipping_address
      if shipping_address.nil?
        if current_user.active_address_count == 0
          return nil
        else
          shipping_address = current_user.addresses[0]
          current_user.update_attribute(:default_shipping_address_id, shipping_address.id)
        end
      end
      shipping_address
    end
  end
  
  def get_last_order(user_id=nil, not_null_field)
    if user_id.nil? && @current_user
      user_id = @current_user.id
    elsif user_id.nil?
      return nil
    end
    
    begin
      Order.find(:all, :conditions => "user_id = #{user_id} and #{not_null_field} is not null", :order => "created_at desc", :limit => 1).first
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end
end
