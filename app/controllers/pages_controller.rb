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
    @top_menu_page = :pricing
    @vc_box = Product.find(Rails.application.config.our_box_product_id)
    @vc_box_count_1_months_1_disc = Discount.new(@vc_box, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @vc_box_count_2_months_1_disc = Discount.new(@vc_box, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @vc_box_count_3_months_1_disc = Discount.new(@vc_box, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @vc_box_count_1_months_2_disc = Discount.new(@vc_box, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @vc_box_count_2_months_2_disc = Discount.new(@vc_box, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @vc_box_count_3_months_2_disc = Discount.new(@vc_box, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @vc_box_count_1_months_3_disc = Discount.new(@vc_box, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    @vc_box_count_2_months_3_disc = Discount.new(@vc_box, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    @vc_box_count_3_months_3_disc = Discount.new(@vc_box, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    
    @cust_box = Product.find(Rails.application.config.your_box_product_id)
    @cust_box_count_1_months_1_disc = Discount.new(@cust_box, Discount::CF_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @cust_box_count_2_months_1_disc = Discount.new(@cust_box, Discount::CF_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @cust_box_count_3_months_1_disc = Discount.new(@cust_box, Discount::CF_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @cust_box_count_1_months_2_disc = Discount.new(@cust_box, Discount::CF_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @cust_box_count_2_months_2_disc = Discount.new(@cust_box, Discount::CF_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @cust_box_count_3_months_2_disc = Discount.new(@cust_box, Discount::CF_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @cust_box_count_1_months_3_disc = Discount.new(@cust_box, Discount::CF_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    @cust_box_count_2_months_3_disc = Discount.new(@cust_box, Discount::CF_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    @cust_box_count_3_months_3_disc = Discount.new(@cust_box, Discount::CF_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)

    @vc_inventorying = Product.find(Rails.application.config.our_box_inventorying_product_id)
    @vc_inventorying_count_1_months_1_disc = Discount.new(@vc_inventorying, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @vc_inventorying_count_2_months_1_disc = Discount.new(@vc_inventorying, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @vc_inventorying_count_3_months_1_disc = Discount.new(@vc_inventorying, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @vc_inventorying_count_1_months_2_disc = Discount.new(@vc_inventorying, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @vc_inventorying_count_2_months_2_disc = Discount.new(@vc_inventorying, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @vc_inventorying_count_3_months_2_disc = Discount.new(@vc_inventorying, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @vc_inventorying_count_1_months_3_disc = Discount.new(@vc_inventorying, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    @vc_inventorying_count_2_months_3_disc = Discount.new(@vc_inventorying, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    @vc_inventorying_count_3_months_3_disc = Discount.new(@vc_inventorying, Discount::BOX_COUNT_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)

    @cust_inventorying = Product.find(Rails.application.config.your_box_inventorying_product_id)
    @cust_inventorying_count_1_months_1_disc = Discount.new(@cust_inventorying, Discount::CF_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @cust_inventorying_count_2_months_1_disc = Discount.new(@cust_inventorying, Discount::CF_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @cust_inventorying_count_3_months_1_disc = Discount.new(@cust_inventorying, Discount::CF_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_1)
    @cust_inventorying_count_1_months_2_disc = Discount.new(@cust_inventorying, Discount::CF_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @cust_inventorying_count_2_months_2_disc = Discount.new(@cust_inventorying, Discount::CF_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @cust_inventorying_count_3_months_2_disc = Discount.new(@cust_inventorying, Discount::CF_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_2)
    @cust_inventorying_count_1_months_3_disc = Discount.new(@cust_inventorying, Discount::CF_DISCOUNT_THRESHOLD_1, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    @cust_inventorying_count_2_months_3_disc = Discount.new(@cust_inventorying, Discount::CF_DISCOUNT_THRESHOLD_2, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    @cust_inventorying_count_3_months_3_disc = Discount.new(@cust_inventorying, Discount::CF_DISCOUNT_THRESHOLD_3, Discount::MONTH_COUNT_DISCOUNT_THRESHOLD_3)
    
    @vc_box_no_discount_disc = Discount.new(@vc_box, 1, 1)
    @vc_inv_no_discount_disc = Discount.new(@vc_inventorying, 1, 1)
    @cust_box_no_discount_disc = Discount.new(@cust_box, 1, 1)
    @cust_inv_no_discount_disc = Discount.new(@cust_inventorying, 1, 1)
    @return_box_product = Product.find(Rails.application.config.return_box_product_id)
    @return_item_product = Product.find(Rails.application.config.item_mailing_product_id)
    @donate_item_product = Product.find(Rails.application.config.item_donation_product_id)
    @stocking_product = Product.find(Rails.application.config.stocking_fee_product_id)
  end
  
  def privacy
    @vc_address = Address.find(Rails.application.config.fedex_vc_address_id)
  end
  
  def contact
    @top_menu_page = :contact
    @error_messages = Hash.new
    @vc_address = Address.find(Rails.application.config.fedex_vc_address_id)
  end
  
  def contact_post
    @vc_address = Address.find(Rails.application.config.fedex_vc_address_id)
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
      AdminMailer.deliver_interested_person_added(person)
    end
  end
  
  def fedex_unavailable
    
  end
  
  def request_confirmation
    
  end
  
  def test_validate_address
    if (!params[:address].nil?)
      fedex = Fedex::Base.new(
         :auth_key => Rails.application.config.fedex_auth_key,
         :security_code => Rails.application.config.fedex_security_code,
         :account_number => Rails.application.config.fedex_account_number,
         :meter_number => Rails.application.config.fedex_meter_number, 
         :debug => Rails.application.config.fedex_debug
       )
      
       @address = Address.new(params[:address])
       
       address_hash = {
         :street_lines => @address.address_line_2.blank? ? [@address.address_line_1] : [@address.address_line_1, @address.address_line_2],
         :city => @address.city,
         :state => @address.state, 
         :zip => @address.zip,
         :country => @address.country
       }
        
       # this should really fail gracefully by catching any exception and telling the user that their address could not be validated,
       # and maybe even using the airbrake interface to send an email?
       @address_report = fedex.validate_address(:address => address_hash)
    else
      @address = Address.new
    end
  end
  
  def marketing_hit
    source = params[:s]
    
    MarketingHit.create!(:source => source) unless source.blank?
    
    redirect_to "/"
  end
  
  private 
  
  def email_post(action, email, user=nil)
    @error_messages = Hash.new
  
    if not email =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      @error_messages[:email] = "Please enter a valid email."
    end
  
    if params[:comment].blank? || params[:comment][:text].blank?
      @error_messages[:text] = "Please enter text."
    end
  
    if action == :support
      if @error_messages.empty?
        AdminMailer.deliver_support_post(email, params[:comment][:text], request.remote_ip, user)
      else
        render :action => "support"
      end
    else
      if @error_messages.empty?
        AdminMailer.deliver_contact_post(email, params[:comment][:text], request.remote_ip)
      else
        render :action => "contact"
      end
    end
  end
end