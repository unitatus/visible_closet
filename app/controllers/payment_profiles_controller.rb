class PaymentProfilesController < ApplicationController
	authorize_resource
	
	def ssl_required?
    true
  end
  
  def index
  end
  
  def new
    if current_user.active_address_count == 0
      redirect_to "/addresses/new?source_c=payment_profiles&source_a=new" and return
    end
    
    @profile = PaymentProfile.new
    
    if not params[:source_c].blank?
      session[:source_c] = params[:source_c].to_sym
      session[:source_a] = params[:source_a].to_sym
    end
  end
  
  def new_default_payment_profile
    @profile = PaymentProfile.new
    @addresses = current_user.addresses
  end
  
  def create_default_payment_profile
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
    
    if !@profile.save
      @addresses = current_user.addresses
      # This is to prevent the selected billing address (if any) from showing up in the new address form
      if params[:payment_profile][:billing_address_id] != "on"
        @profile.billing_address = Address.new
      end
      render :new_default_payment_profile
    else
      @profile.user.default_payment_profile = @profile
      @profile.user.save
      redirect_to "/account/store_more_boxes"
    end
  end
  
  def create
    @profile = PaymentProfile.new(params[:payment_profile])
    
    # Double-check, since in this case payment profile can't be saved without billing address id
    if params[:payment_profile][:billing_address_id].blank?
      @profile.errors[:billing_address_id] = "Please select billing address."
    end
    
    @profile.user_id = current_user.id
    
    if @profile.save
      @profile = PaymentProfile.find(@profile.id)
      
      if params[:default] == "1" || current_user.payment_profile_count == 1
        current_user.default_payment_profile = @profile
        current_user.save
      end
      
      if not (session[:source_c].blank?) # we came from somewhere; return there        
        redirect_to :controller => session[:source_c], :action => session[:source_a]
        session[:source_c] = nil
        session[:source_a] = nil
      else
        render :action => "index"
      end
    else
      puts("Failed to save payment profile. Errors are " << @profile.errors.inspect)
      # Need to completely reset @profile, as otherwise Rails will make the form an edit form if this profile saved but the authorize.net profile was not created.
      @profile = PaymentProfile.new_from(@profile)
      render :action => "new"
    end
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
end