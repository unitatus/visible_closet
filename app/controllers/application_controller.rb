class ApplicationController < ActionController::Base
  include SslRequirement
  before_filter :check_uri
      
  protect_from_forgery
  
  # For every controller, make sure that it checks authorization or skips it explicitly, unless the controller is one of the devise controllers
  check_authorization :unless => :skip_authorization
  
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to access_denied_url
  end
  
  # Redirect to www.thevisiblecloset.com if the user hit anything other than that url
  def check_uri
    redirect_to request.protocol + "www." + request.host_with_port + request.request_uri if !/^www/.match(request.host) if Rails.env == 'production'
  end
  
  # This is mainly for the autocomplete item search, which for some reason doesn't work from a non-secure page calling a secure page
  def ssl_required?
    return user_signed_in?
  end
  
  def after_sign_in_path_for(resource_or_scope)
    if resource_or_scope.is_a?(User) && resource_or_scope.sign_in_count < 2 && resource.default_shipping_address.nil?
      "/addresses/new_default_shipping_address"
    else
      super
    end
  end
  
  def skip_authorization
    return devise_controller? || params[:controller] == "switch_user"
  end
  
  # This is a bit of a hack -- the warden code below is taken from devise -- but it is the only way I could come up with to
  # safely intercept current user, since otherwise the current_user method is added dynamically at the end of the class load
  # process by devise (which means that if we decorated that method it would either break the console (because devise does 
  # not load there first) or it would not work the first time you hit the code in production). -DZ
  #
  # Note: we are not using switch_user (a gem for switching users) or having devise log out - log in because to do so 
  # causes cookie problems in production.
  #
  # Note also: this method must live in application controller for the hack to work (not in the helper)
  def current_user
    @current_user ||= warden.authenticate(:scope => :user)
    
    if @current_user.nil?
      return nil
    end
    
    if @current_user.manager? && @current_user.impersonating?
      @current_user.acting_as
    else
      @current_user
    end    
  end
end
