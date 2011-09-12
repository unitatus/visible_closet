class AddressesController < ApplicationController
  authorize_resource

  def ssl_required?
    true
  end

  # GET /addresses
  # GET /addresses.xml
  def index
    @addresses = Address.find_active(current_user.id, :order => :first_name)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @addresses }
    end
  end
  
  def new_default_shipping_address
    @user = current_user
    @address = Address.new
  end
  
  def set_default_shipping_address
    do_create("/payment_profiles/new_default_payment_profile", "confirm_new_default_shipping_address", "new_default_shipping_address", true, false)
  end
  
  def admin_new_address
    @address = Address.new
    @address.user_id = params[:user_id]
    @user = User.find(params[:user_id])
  end
  
  def admin_create_address
    do_create("/admin/user/#{params[:user_id]}", "admin_confirm_address", "admin_new_address", false, true)
  end

  def override_fedex
    if current_user.default_payment_profile.nil?
      # We have already checked on validation and saved, so just move forward
      redirect_to :controller => "payment_profiles", :action => "new_default_payment_profile" and return
    elsif current_user.order_count == 0
      redirect_to :controller => "account", :action => "store_more_boxes"
    else
      @addresses = Address.find_active(current_user.id, :order => :first_name)
      render :action => "index"
    end
  end
  
  def admin_fedex_override
    @address = Address.find(params[:address_id])
    redirect_to "/admin/user/#{@address.user_id}"
  end
  
  def confirm_new_default_shipping_address
    
  end
  
  def confirm_new_checkout_shipping_address
    
  end
  
  def confirm_address
    
  end
  
  def admin_confirm_address
    
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
  
  def new_checkout_shipping_address
    @addresses = current_user.addresses
    @address = Address.new
  end
  
  def set_checkout_shipping_address
    if params[:shipping_address_id].blank?
      flash[:notice] = "Please select a shipping address option."
      
      # set defaults as in a new address
      new_checkout_shipping_address
      render :action => 'new_checkout_shipping_address' and return
    end
    
    cart_item = CartItem.find(params[:cart_item_id])
    
    if params[:shipping_address_id] == "on" # new address
      @address = Address.new(params[:address])
      @address.user = current_user
      
      if @address.save
        # It is possible that the user could go someplace else after entering the new address and before checking the FedEx validation. In this case,
        # we want the cart item to reflect the new unvalidated address.
        cart_item.address = @address
        cart_item.save
        
        if @address.externally_valid_with_save?
          redirect_to '/account/check_out' and return
        else
          render :action => 'confirm_new_checkout_shipping_address'
        end
      else
        flash[:notice] = "Please correct the following errors."
        @addresses = current_user.addresses
        render :new_checkout_shipping_address and return
      end
    else # user chose another address
      cart_item.address = Address.find(params[:shipping_address_id])
      cart_item.save
      
      redirect_to :action => 'check_out' and return
    end
  end
  
  def update_new_checkout_shipping_address
    @address = Address.find(params[:id])
    @address.update_attributes(params[:address])
    
    if @address.save
      if @address.externally_valid_with_save?
        redirect_to '/account/check_out'
      else
        render :action => 'confirm_new_checkout_shipping_address'
      end
    else
      flash[:notice] = "Please correct the following errors."
      render :action => 'correct_new_checkout_shipping_address'
    end
  end
  
  # GET /addresses/new
  # GET /addresses/new.xml
  def new
    @address = Address.new
    @address.user_id = current_user.id

    if not params[:source_c].blank?
      session[:source_c] = params[:source_c]
      session[:source_a] = params[:source_a]
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @address }
    end
  end

  # GET /addresses/1/edit
  def edit
    @address = Address.find_active_by_id_and_user_id(params[:id], current_user.id)
  end

  # POST /addresses
  # POST /addresses.xml
  def create
    do_create(addresses_url, "confirm_address", "new", false, false)
  end

  # PUT /addresses/1
  # PUT /addresses/1.xml
  def update
    @address = Address.find_active_by_id_and_user_id(params[:id], current_user.id)

    if @address.update_attributes(params[:address])
      if @address.externally_valid_with_save?
        redirect_to(addresses_url)
      else
        render :action => "confirm_address"
      end
    else
      render :action => "edit"
    end
  end

  # DELETE /addresses/1
  # DELETE /addresses/1.xml
  def destroy
    if current_user.default_shipping_address_id.to_s == params[:id]
      @messages = Array.new
      @messages << "Cannot delete default shipping address."
      @addresses = Address.find_active(current_user.id, :order => :first_name)
      render :index
    else
      @address = Address.find_active_by_id_and_user_id(params[:id], current_user.id)
      @address.status = 'inactive'
      @address.save

      respond_to do |format|
          format.html { redirect_to(addresses_url) }
          format.xml  { head :ok }
      end
    end
  end
  
  # PUT /addresses/id/set_default_shipping
  def set_default_shipping
    current_user.default_shipping_address = Address.find(params[:id])
    current_user.save
    @addresses = Address.find_active(current_user.id, :order => :first_name)
    
    render :index
  end
  
  private
  
  def do_create(success_redirect, confirmation_action, failure_action, set_default_shipping_address, admin)
    @user = admin ? User.find(params[:user_id]) : current_user
    if params[:id].blank?
      @address = Address.new(params[:address])
    else
      @address = Address.find_active_by_id_and_user_id(params[:id], @user.id)
      @address.update_attributes(params[:address])
    end
    
    @address.user = @user
    
    if set_default_shipping_address
      @user.default_shipping_address = @address
    end
    
    if @address.save
      @user.save
      if @address.externally_valid_with_save?
        if not (session[:source_c].blank?) # we came from somewhere; return there
          redirect_to :controller => session[:source_c], :action => session[:source_a]
          session[:source_c] = nil
          session[:source_a] = nil
        else
          redirect_to(success_redirect) and return
        end
      else
        render :action => confirmation_action and return
      end
    else
      render :action => failure_action and return
    end
  end
end
