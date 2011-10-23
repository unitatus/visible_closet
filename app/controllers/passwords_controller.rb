class PasswordsController < Devise::PasswordsController
  
  def ssl_required?
    true
  end

end
