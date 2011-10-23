class RegistrationsController < Devise::RegistrationsController
  
  def ssl_required?
    true
  end

end
