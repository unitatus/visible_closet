class PagesController < ApplicationController
  skip_authorization_check
  
	def how_it_works
	  @top_menu_page = :hiw
	end
	
	def restrictions
	  @top_menu_page = :hiw  
  end
  
  def packing_tips
    @top_menu_page = :hiw
  end
  
  def right_for_me
    @top_menu_page = :hiw
  end
  
  def faq
    @top_menu_page = :hiw
  end
  
  def legal
    @top_menu_page = :hiw
  end
  
  def pricing
    @top_menu_page = :hiw
  end
  
  def contact
    @top_menu_page = :contact
  end
  
  def support
    
  end
  
  def register_block
    
  end
  
  def register_interest
    InterestedPerson.create!(:email => params[:email]) if !params[:email].blank? && InterestedPerson.find_by_email(params[:email]).nil?
    
    redirect_to "/"
  end
end