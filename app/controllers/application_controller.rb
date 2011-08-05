class ApplicationController < ActionController::Base
  include SslRequirement
  
  protect_from_forgery
  
  # For every controller, make sure that it checks authorization or skips it explicitly, unless the controller is one of the devise controllers
  check_authorization :unless => :devise_controller?
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to access_denied_url
  end
  
  def ssl_required?
    #return false if RAILS_ENV != 'production'
    
    # otherwise, use the filters.
    return_val = super
    
    return_val
  end
  
  def after_sign_in_path_for(resource_or_scope)
    if resource_or_scope.is_a?(User) && resource_or_scope.sign_in_count < 2
      "/account/store_more_boxes"
    else
      super
    end
  end
end
