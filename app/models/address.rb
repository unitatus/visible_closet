# == Schema Information
# Schema version: 20110810161902
#
# Table name: addresses
#
#  id             :integer         not null, primary key
#  first_name     :string(255)
#  last_name      :string(255)
#  day_phone      :string(255)
#  evening_phone  :string(255)
#  address_line_1 :string(255)
#  address_line_2 :string(255)
#  city           :string(255)
#  state          :string(255)
#  zip            :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  address_name   :string(255)
#  user_id        :integer
#  country        :string(255)
#  status         :string(255)
#  comment        :string(255)
#

class Address < ActiveRecord::Base
  require 'soap/wsdlDriver'

  belongs_to :user

  validates_presence_of :first_name, :message => "can't be blank"
  validates_presence_of :last_name, :message => "can't be blank"
  validates_presence_of :day_phone, :message => "can't be blank"
  validates_presence_of :address_line_1, :message => "can't be blank"
  validates_length_of :address_line_1, :maximum => 30, :message => "Fedex cannot accept address lines longer than 30 characters"
  validates_length_of :address_line_2, :maximum => 30, :message => "Fedex cannot accept address lines longer than 30 characters"
  validates_presence_of :city, :message => "can't be blank"
  validates_presence_of :state, :message => "State must be selected"
  validates_presence_of :zip, :message => "can't be blank"
  validate :external_validation, :on => :create

  validates_length_of :day_phone, :minimum => 10, :maximum => 10, :message => "Please enter a 10-digit phone number", :unless => :skip_day_content_validation
  validates_numericality_of :day_phone, :message => "Please enter only numbers for the phone", :unless => :skip_day_content_validation
  validates_length_of :evening_phone, :minimum => 10, :maximum => 10, :message => "Please enter a 10-digit phone number", :unless => :skip_evening_content_validation
  validates_numericality_of :evening_phone, :message => "Please enter only numbers for the phone", :unless => :skip_evening_content_validation

  def skip_day_content_validation
    day_phone.blank?
  end

  def skip_evening_content_validation
    evening_phone.blank?
  end

  def day_phone=(phone_number)
    if phone_number.is_a?(String)
      phone_number = phone_number.gsub(/\D/, '')
    end
    
    super(phone_number)
  end

  # Hard coded country for now
  def Address.new(params=nil)
    new_address = super(params)
    new_address.country = "US"
    new_address.status = "active"
    
    new_address
  end
  
  def Address.find_by_user_id(user_id=nil)
    raise "Do not use this method. You must specify find_active or one of the generated methods, or implement a new method"
  end
  
  def Address.find_by_id_and_user_id(id=nil, user_id=nil)
    raise "Do not use this method. You must specify find_active_by... or one of the generated methods, or implement a new method"    
  end
  
  def Address.find_active(user_id, order=nil)
    find_all_by_user_id_and_status(user_id, "active", order)
  end
  
  def Address.find_active_by_id_and_user_id(id, user_id)
    find_by_id_and_user_id_and_status(id, user_id, "active")
  end
  
  def summary
    return_str = self.address_line_1
    return_str << (self.address_line_2.blank? ? "" : " " + self.address_line_2)
    return_str << (" " + self.city)
    return_str << (" " + self.state)
    return_str << (" " + self.zip)
    
    return_str
  end
  
  def destroy
    if !user.nil? && user.default_shipping_address == self
      user.update_attribute(:default_shipping_address_id, nil)
    end
    super
  end
  
  def external_validation
    if !errors.empty?
      # there are errors. Back out -- these can cause fatal consequences in fedex call.
      return false
    end 
    
    fedex = Fedex::Base.new(
       :auth_key => Rails.application.config.fedex_auth_key,
       :security_code => Rails.application.config.fedex_security_code,
       :account_number => Rails.application.config.fedex_account_number,
       :meter_number => Rails.application.config.fedex_meter_number, 
       :debug => Rails.application.config.fedex_debug
     )
    
     address_hash = {
       :street_lines => address_line_2.blank? ? [address_line_1] : [address_line_1, address_line_2],
       :city => city,
       :state => state, 
       :zip => zip,
       :country => country
     }
      
     # this should really fail gracefully by catching any exception and telling the user that their address could not be validated,
     # and maybe even using the airbrake interface to send an email?
     @address_report = fedex.validate_address(:address => address_hash)
     
     if @address_report[:line_1][:suggested_value] != self.address_line_1 && @address_report[:changes_suggested]
       errors[:address_line_1] = "We didn't recognize the entry \"#{self.address_line_1}\" for this address. A suggested value has been entered."
       self.address_line_1 = @address_report[:line_1][:suggested_value]
     end

     if @address_report[:line_2][:suggested_value] != self.address_line_2 && @address_report[:changes_suggested]
       if self.address_line_2.blank?
         errors[:address_line_2] = "Our address system suggested a value for address line 2."
       else
         if @address_report[:line_2][:suggested_value].blank?
           errors[:address_line_2] = "Our address system suggested a blank for address line 2 instead of \"#{self.address_line_2}\""
         else
           errors[:address_line_2] = "We didn't recognize the entry \"#{self.address_line_2}\" for this address. A suggested value has been entered."
         end
       end
       self.address_line_2 = @address_report[:line_2][:suggested_value]
     end
     
     if @address_report[:city][:suggested_value] != self.city && @address_report[:changes_suggested]
       errors[:city] = "We didn't recognize the entry \"#{self.city}\" for this address. A suggested value has been entered."
       self.city = @address_report[:city][:suggested_value]
     end
     
     if @address_report[:postal_code][:suggested_value] != self.zip && @address_report[:changes_suggested]
       errors[:zip] = "We didn't recognize the entry \"#{self.zip}\" for this address. A suggested value has been entered."
       self.zip = @address_report[:postal_code][:suggested_value]
     end

     if !@address_report[:success] && @address_report[:changes_suggested]
       errors[:fedex] = "We were unable to verify the address you entered, but have suggestions. See below for details and to accept or reject the suggestions."
     elsif !@address_report[:success]
       errors[:fedex] = "We were unable to verify the address you entered. Please check your entries, or <a href=\"/contact\">contact us</a> for questions. <br>At this time we can only accept addresses that FedEx can ship to."
     end
   end
  
  def changes_suggested?
    @address_report.nil? ? false : @address_report[:changes_suggested]
  end
  
  def submitted_value(value)
    read_attribute(value)
  end

  def external_error_messages
    translated_messages = Array.new
    
    if @address_report.nil?
      return translated_messages
    end
    
    @address_report[:messages].each do |msg|
      translated_message = translate_external_message(msg)
      translated_messages << translated_message unless translated_message.blank?
    end
    
    translated_messages
  end
  
  private
  
  def translate_external_message(msg)
    case msg
    when "MODIFIED_TO_ACHIEVE_MATCH"
      return nil
    when "APARTMENT_NUMBER_NOT_FOUND"
      return "Apartment Number Not Found"
    when "APARTMENT_NUMBER_REQUIRED"
      return "Apartment Number Required"
    when "NORMALIZED"
      return nil
    when "REMOVED_DATA"
      return nil
    when "BOX_NUMBER_REQUIRED"
      return "Box Number Required"
    when "NO_CHANGES"
      return nil
    when "STREET_RANGE_MATCH"
      return nil
    when "BOX_NUMBER_MATCH"
      return nil
    when "RR_OR_HC_MATCH"
      return nil
    when "CITY_MATCH"
      return nil
    when "POSTAL_CODE_MATCH"
      return nil
    when "RR_OR_HC_BOX_NUMBER_NEEDED"
      return "Rural Route or HC Box Number Needed"
    when "FORMATTED_FOR_COUNTRY"
      return nil
    when "APO_OR_FPO_MATCH"
      return nil
    when "GENERAL_DELIVERY_MATCH"
      return nil
    when "FIELD_TRUNCATED"
      return nil
    when "UNABLE_TO_APPEND_NON_ADDRESS_DATA"
      return "Unable to Append Non-Address Data"
    when "INSUFFICIENT_DATA"
      return "Insufficient Data Was Provided To Identify This Address"
    when "HOUSE_OR_BOX_NUMBER_NOT_FOUND"
      return "House Or Box Number Not Found"
    when "POSTAL_CODE_NOT_FOUND"
      return "Postal Code Not Found"
    when "INVALID_COUNTRY"
      return "Invalid Country"
    when "SERVICE_UNAVAILABLE_FOR_ADDRESS"
      return "FedEx Service is Unavailable for this Address"
    else
      puts("Unknown messages " + msg + " was returned from FedEx.")
      msg
    end
  end
end

