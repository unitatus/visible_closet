class AccountController < ApplicationController
  # The account controller actions are only accessible for someone who is signed up as a user.
  authorize_resource :class => false

  before_filter :set_menu

  def ssl_required?
    true
  end

  def index
    @last_payment_transaction = PaymentTransaction.find_by_user_id(current_user.id, :order => "created_at DESC")
    # this must be called before the next line, which will alter (but not save) the user
    @next_user_charge_date = current_user.next_charge_date
    user = current_user

    account_balance = user.current_account_balance
    @next_user_charge = account_balance > 0 ? 0 : account_balance * -1
  end
  
  def email_confirmation
    
  end
  
  def invoice_estimate
    @user = current_user

    @user.calculate_subscription_charges # this will add all the charges that will show up at the end of the month
    @start_of_month = DateHelper.start_of_month
  end
  
  def account_history
    @events = Event.all(current_user)
  end
  
  def store_more_boxes
    # If you circumvented the normal sign-up procedures then you must take care of those now
    if current_user.default_shipping_address.nil?
      @address = Address.new
      @user = current_user
      flash[:notice] = "You must create a default shipping address first."
      render "addresses/new_default_shipping_address" and return
    elsif current_user.default_payment_profile.nil?
      @profile = PaymentProfile.new
      @addresses = current_user.addresses
      render "payment_profiles/new_default_payment_profile" and return
    end
    
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
    else
      @cart.remove_cart_item(Rails.application.config.our_box_product_id)
      @cart.remove_cart_item(Rails.application.config.your_box_product_id)
      @cart.remove_cart_item(Rails.application.config.our_box_inventorying_product_id)
      @cart.remove_cart_item(Rails.application.config.your_box_inventorying_product_id)
    end
    
    if params[:box_type] == "vc_boxes"
      box_product_id = Rails.application.config.our_box_product_id
      num_boxes = params[:num_vc_boxes][:num_vc_boxes]
    elsif params[:box_type] == "cust_boxes"
      box_product_id = Rails.application.config.your_box_product_id
      num_boxes = params[:num_cust_boxes][:num_cust_boxes]
    else
      raise "Illegal box type selected."
    end    

    # This is a numeric check. Why doesn't this exist in Ruby?
    if params[:num_months][:num_months].to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) != nil
      committed_months = params[:num_months][:num_months]
    else
      committed_months = 1
    end

    @cart.add_cart_item(box_product_id, num_boxes, committed_months)
    
    # The following code is for the cart maintenance pages, which as of 8/17/2011 are turned off.
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
      redirect_to :action => 'check_out'
    end
  end
  
  def external_addresses_validate
    
  end

  def cart
    @turn_cart_off = true
    @cart = Cart.find_active_by_user_id(current_user.id)
    if (@cart.nil?)
      @cart = Cart.new
    end
  end

  def update_cart_item
    @turn_cart_off = true
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
    begin
      cart_item = CartItem.find(params[:cart_item_id])
    rescue
      # the user probably just hit refresh
      @cart = current_user.cart
      return
    end
   
    CartItem.delete(params[:cart_item_id])

    flash.now[:notice] = "Cart item removed."

    @cart = Cart.find(cart_item.cart_id)

    render 'cart'
  end

  def check_out_remove_cart_item
    CartItem.delete(params[:id])
    redirect_to :action => "check_out"
  end

  def check_out
    @cart = current_user.cart
    @turn_cart_off = true
    
    if !@cart || @cart.cart_items.empty?
      redirect_to :action => :store_more_boxes
      return
    end

    @cart.quote_shipping
    
    @addresses = current_user.addresses
    
    if @addresses.nil? || @addresses.empty?
      @address = Address.new
      render :action => "add_new_shipping_address"
      return
    elsif current_user.default_payment_profile.nil?
      @profile = PaymentProfile.new
      @addresses = current_user.addresses
      render "payment_profiles/new_default_payment_profile" and return
    end
    
    @order = Order.new
  end

  def add_new_shipping_address
    @address = Address.new
    @address.user_id = current_user.id
  end

  def finalize_check_out
    @cart = current_user.cart

    # The most likely reason why a cart would not be found is because the submit button was clicked twice, and the order previously committed.
    # That means we should render nicely as though it did.
    if @cart.nil?
      @order = Order.find_all_by_user_id(current_user.id, :first, :order => 'created_at DESC').first
      return
    elsif @cart.order # this means we failed the last time through, after the payment was created; be nice about it
      @order = @cart.order
    else
      @order = @cart.build_order(params[:order])
    end
    
    @order.ip_address = request.remote_ip      
    
    if @order.contains_box_orders?
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
    end
    
    if (!@order.purchase) # this saves the order
      fail_checkout
    end
    
    @cart = nil
  end
  
  def fail_checkout
    render 'check_out'    
  end
  
  private 
  
  def set_menu
    @top_menu_page = :account
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
