class RegistrationsController < Devise::RegistrationsController
  ssl_required :new, :create
  
  private

end
