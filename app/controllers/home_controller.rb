class HomeController < ApplicationController
  skip_authorization_check
  
  def index
    @top_menu_page = :home
  end

  def access_denied
    
  end
end
