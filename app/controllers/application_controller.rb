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
end
