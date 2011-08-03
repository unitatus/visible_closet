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
    @vc_box_price = Product.find(Rails.application.config.our_box_product_id).price
    @cust_box_price = Product.find(Rails.application.config.your_box_product_id).price
    @vc_box_inventorying_price = Product.find(Rails.application.config.our_box_inventorying_product_id).price
    @cust_box_inventorying_price = Product.find(Rails.application.config.your_box_inventorying_product_id).price
  end
  
  def contact
    @top_menu_page = :contact
  end
  
  def support
    
  end
  
  def register_block
    
  end
  
  def register_interest
    if !params[:email].blank? && InterestedPerson.find_by_email(params[:email]).nil?
      person = InterestedPerson.create!(:email => params[:email]) 
      AdminMailer.interested_person_added(person).deliver
    end
  end
  
  def fedex_unavailable
    
  end
end