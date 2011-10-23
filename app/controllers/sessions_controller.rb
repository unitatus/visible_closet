class SessionsController < Devise::SessionsController

  def ssl_required?
    true
  end
  
end