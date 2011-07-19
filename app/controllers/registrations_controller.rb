class RegistrationsController < Devise::RegistrationsController
  ssl_required :new, :create
  
  private

  def after_inactive_sign_up_path_for(resource)
    "/pages/beta_thanks"
  end
end
