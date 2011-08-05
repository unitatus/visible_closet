class RegistrationsController < Devise::RegistrationsController
  ssl_required :new, :create
  
  def create
    # First create everything, do the redirects and everything
    super
    
    # now make the associations that are missing because Devise doesn't allow for customizations of create, and Rails can't handle
    # cross referential relationships
    if (@user.errors.size == 0)
      @user.default_shipping_address.user = @user
      @user.default_shipping_address.save
    
      @user.default_payment_profile.billing_address = @user.default_shipping_address
      @user.default_payment_profile.user = @user
      @user.default_payment_profile.create_payment_profile
    
      if !@user.default_payment_profile.save
        raise "Failed to save payment profile after Devise user create"
      else
        return true
      end
    end
  end
  
  private

end
