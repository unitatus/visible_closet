class RegistrationsController < Devise::RegistrationsController
  ssl_required :new, :create
  
  def new
    @billing_address = Address.new
    super
  end
  
  def create
    build_resource

    @billing_address = Address.new
    @billing_address.first_name = params[:baddress_first_name]
    @billing_address.last_name = params[:baddress_last_name]
    @billing_address.day_phone = params[:baddress_day_phone]
    @billing_address.evening_phone = params[:baddress_evening_phone]
    @billing_address.address_line_1 = params[:baddress_address_line_1]
    @billing_address.address_line_2 = params[:baddress_address_line_2]
    @billing_address.city = params[:baddress_city]
    @billing_address.state = params[:baddress_state]
    @billing_address.zip = params[:baddress_zip]
    
    # Two objects, need to call valid twice regardless so we get the messages processed
    both_valid = @billing_address.valid?
    both_valid = resource.valid? && both_valid

    if both_valid
      @billing_address.save
      resource.save
      
      # Can't do this beforehand because of the cross referentiality -- we'll get an infinite loop
      resource.default_shipping_address.user = resource
      resource.default_payment_profile.billing_address = @billing_address
      resource.default_payment_profile.user = resource
      @billing_address.user = resource
      
      resource.default_shipping_address.save
      resource.default_payment_profile.save
      @billing_address.save
      
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => redirect_location(resource_name, resource)
      else
        set_flash_message :notice, :inactive_signed_up, :reason => resource.inactive_message.to_s if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords(resource)
      respond_with_navigational(resource) { render_with_scope :new }
    end
  end
  
  # def create
  #   @billing_address = Address.new
  #   
  #   # First create everything, do the redirects and everything
  #   super
  #   
  #   # now make the associations that are missing because Devise doesn't allow for customizations of create, and Rails can't handle
  #   # cross referential relationships
  #   if (@user.errors.size == 0)
  #     @user.default_shipping_address.user = @user
  #     @user.default_shipping_address.save
  #   
  #     @user.default_payment_profile.billing_address = @user.default_shipping_address
  #     @user.default_payment_profile.user = @user
  #     @user.default_payment_profile.create_payment_profile
  #   
  #     if !@user.default_payment_profile.save
  #       raise "Failed to save payment profile after Devise user create"
  #     else
  #       return true
  #     end
  #   end
  # end
  
  def after_inactive_sign_up_path_for(resource)
    "/pages/request_confirmation"
  end
  
  private

end
