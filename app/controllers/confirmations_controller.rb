class ConfirmationsController < Devise::ConfirmationsController

  def ssl_required?
    true
  end

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      set_flash_message(:notice, :confirmed) if is_navigational_format?
      @this_user = resource

      # For the sign-in form to behave properly, we need the following code from sessions_controller. We can't just redirect,
      # because we have to tell the page information about this user in order for it to communicate to the user correctly.
      # Sometimes rails is lame.
      resource = build_resource
      clean_up_passwords(resource)
      
      render "email_confirmation"
    else
      respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render_with_scope :new }
    end
  end
  
  def email_confirmation
  end
end