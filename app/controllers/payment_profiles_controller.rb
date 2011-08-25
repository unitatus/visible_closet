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
  
  def new_default_payment_profile
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
    do_create("/account/store_more_boxes", :new_default_payment_profile)
  end
  
  def create
    do_create("/account/home", :new)
  end
  
  def set_default
    if not params[:id].blank?
      current_user.update_attribute(:default_payment_profile_id, params[:id])
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
      profile.update_attribute(:active, false)
      
      @profiles = current_user.payment_profiles

      if @profiles.size == 0
        @profile = PaymentProfile.new
        render :action => "new"
      else
        render :action => "index"
      end
    end
  end
  
  private
  
  def do_create(success_redirect, failure_render)
    @profile = PaymentProfile.new(params[:payment_profile])
    @profile.user = current_user

    # Because we have "options" in how the user specifies the address, we must ignore the auto-setting above and manually set billing address properties.
    # FYI, it seems that what happens above is if the user selected a billing address then it gets set, then all the empty attributes get set
    # on top of it.
    if params[:payment_profile][:billing_address_id] == "on" # user entered an address
      @profile.billing_address = Address.new(params[:payment_profile][:billing_address_attributes])
    else # user selected an address
      @profile.billing_address_id = params[:payment_profile][:billing_address_id]
    end
    
    if @profile.save
      if params[:default] == "1" || current_user.payment_profile_count == 1
        current_user.default_payment_profile = @profile
        current_user.save
      end
      
      if not (session[:source_c].blank?) # we came from somewhere; return there        
        redirect_to :controller => session[:source_c], :action => session[:source_a]
        session[:source_c] = nil
        session[:source_a] = nil
      else
        redirect_to success_redirect
      end
    else
      @addresses = current_user.addresses
      # This is to prevent the selected billing address (if any) from showing up in the new address form
      if params[:payment_profile][:billing_address_id] != "on"
        @profile.billing_address = Address.new
      end
      render failure_render
    end
  end
end