class PagesController < ApplicationController
  require 'soap/wsdlDriver'

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
    @error_messages = Hash.new
  end
  
  def contact_post
    email_post(:contact, params[:email])
  end
  
  def support
    if current_user.nil?
      redirect_to access_denied_url
    end
    @error_messages = Hash.new
  end
  
  def support_post
    if current_user.nil?
      redirect_to access_denied_url and return
    end
    
    email_post(:support, current_user.email, current_user)
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
  
  def request_confirmation
    
  end
  
  def test_validate_address
    fedex = Fedex::Base.new(
       :auth_key => Rails.application.config.fedex_address_validation_auth_key,
       :security_code => Rails.application.config.fedex_address_validation_security_code,
       :account_number => Rails.application.config.fedex_address_validation_account_number,
       :meter_number => Rails.application.config.fedex_address_validation_meter_number, 
       :debug => Rails.application.config.fedex_debug
     )
     
     address = {
       :street_lines => ["140 Custer Ave", "Apt 1"],
       :city => "Evanston",
       :state => "IL", 
       :zip => "60202",
       :country => "US"
     }
     
     address = {
       :street_lines => ["1000 FedEx Dr", "Barcode Analysis"],
       :city => "Moon Township",
       :state => "PA", 
       :zip => "15108",
       :country => "US"
     }
     
     @address_report = fedex.validate_address(:address => address)
  end
  
  private 
  
  def email_post(action, email, user=nil)
    @error_messages = Hash.new
  
    if not email =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      @error_messages[:email] = "Please enter a valid email."
    end
  
    if params[:comment][:text].blank?
      @error_messages[:text] = "Please enter text."
    end
  
    if action == :support
      if @error_messages.empty?
        AdminMailer.support_post(email, params[:comment][:text], request.remote_ip, user).deliver
      else
        render :action => "support"
      end
    else
      if @error_messages.empty?
        AdminMailer.contact_post(email, params[:comment][:text], request.remote_ip).deliver
      else
        render :action => "contact"
      end
    end
  end
end