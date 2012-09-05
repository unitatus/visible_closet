class PaymentProfilesController < ApplicationController
	authorize_resource
	
	def ssl_required?
    true
  end
  
  def index
  end
  
  def new
    if current_user.default_shipping_address.nil?
      flash[:notice] = "You must create a default shipment address first."
      @user = current_user
      @address = Address.new
      render :action => "addresses/new_default_shipping_address" and return
    end
    
    @profile = PaymentProfile.new
    @addresses = current_user.addresses
    
    if not params[:source_c].blank?
      session[:source_c] = params[:source_c].to_sym
      session[:source_a] = params[:source_a].to_sym
    end
  end
  
  def edit
    @profile = PaymentProfile.find_by_id_and_user_id(params[:id], current_user.id)
    @addresses = current_user.addresses
    @new_address = Address.new
  end
  
  def update
    do_create_or_update("/payment_profiles", :edit)
  end
  
  def new_default_payment_profile
    @force_default = true
    
    if current_user.default_shipping_address.nil?
      flash[:notice] = "You must create a default shipment address first."
      @user = current_user
      @address = Address.new
      render :action => "addresses/new_default_shipping_address" and return
    end
    
    @profile = PaymentProfile.new
    @addresses = current_user.addresses
  end
  
  def create_default_payment_profile
    @force_default = true
    @user = current_user
    @addresses = current_user.addresses
    save_default_profile = @user.default_payment_profile
    
    if @user.has_rectify_payments?
      if do_create_or_update
        puts "The payment profile was created with id #{@profile.id} and with customer profile id #{@profile.identifier}."
        if @user.resolve_rectify_payments
          redirect_to "/account/home"
        else
          @user.default_payment_profile = save_default_profile
          @user.save
          @profile.inactivate
          @profile = PaymentProfile.clone(@profile)
          if params[:payment_profile][:billing_address_id] != "on"
            @profile.billing_address = Address.new
          end          
          @profile.errors.add("", "The credit card supplied was unable to process the current overdue charges on this account. Please enter another.")
          render :new_default_payment_profile
        end
      else
        render :new_default_payment_profile
      end
    else # rectify check
      do_create_or_update((@user.has_cart_items? ? "/account/check_out" : "/account/store_more_boxes"), :new_default_payment_profile)
    end
  end
  
  def create
    do_create_or_update("/account/home", :new)
  end
  
  def set_default
    if not params[:id].blank?
      current_user.update_attribute(:default_payment_profile_id, params[:id])
    end
    
    if current_user.has_rectify_payments?
      current_user.resolve_rectify_payments
      # if this fails, do nothing
    end
    
    render :index
  end
  
  def destroy
    if current_user.default_payment_profile_id.to_s == params[:id]
      @messages = Array.new
      @messages << "Cannot delete default payment method."
      @profile = PaymentProfile.new
      render :action => "index"
    else
      profile = PaymentProfile.find(params[:id])
      profile.inactivate
      
      @profiles = current_user.active_payment_profiles

      if @profiles.size == 0
        @profile = PaymentProfile.new
        render :action => "new"
      else
        render :action => "index"
      end
    end
  end
  
  private
  
  def do_create_or_update(success_redirect=nil, failure_render=nil)
    @user ||= current_user
    @profile = params[:id].blank? ? @user.payment_profiles.build(params[:payment_profile]) : PaymentProfile.find_by_id_and_user_id(params[:id], @user.id)

    if !@profile.new_record?
      @profile.update_attributes(params[:payment_profile])
    end

    # Because we have "options" in how the user specifies the address, we must ignore the auto-setting above and manually set billing address properties.
    # FYI, it seems that what happens above is if the user selected a billing address then it gets set, then all the empty attributes get set
    # on top of it.
    if params[:payment_profile][:billing_address_id] == "on" # user entered an address
      @profile.billing_address = current_user.addresses.build(params[:payment_profile][:billing_address_attributes])
    elsif params[:payment_profile][:billing_address_id].blank? # user did not enter an address
      @profile.billing_address = nil
    else # user selected an address
      @profile.billing_address = Address.find(params[:payment_profile][:billing_address_id])
    end
    
    if @profile.save
      if params[:default] == "1" || current_user.payment_profile_count == 1
        @profile.user.default_payment_profile = @profile
        @profile.user.save
      end
      
      if not (session[:source_c].blank?) # we came from somewhere; return there        
        redirect_to :controller => session[:source_c], :action => session[:source_a]
        session[:source_c] = nil
        session[:source_a] = nil
      else
        if success_redirect
          redirect_to success_redirect
        else
          return true
        end
      end
    else
      @addresses = current_user.addresses
      if params[:payment_profile][:billing_address_id] == "on"
        @new_address = @profile.billing_address
        current_user.addresses.delete(@profile.billing_address) # so new address doens't show up in the list of addresses
      else
        @new_address = Address.new
      end
      # This is to prevent the selected billing address (if any) from showing up in the new address form.
      # The annoying reset logic is because if the profile succeeded locally but failed with authorize.net then it must be
      # destroyed, but if destroyed, we can't modify it. Arg!
      # if params[:payment_profile][:billing_address_id] != "on"
      #   @profile = PaymentProfile.clone(@profile)
      #   @profile.billing_address = Address.new
      # end
      if failure_render
        render failure_render
      else
        return false
      end
    end
  end
end