# == Schema Information
# Schema version: 20110820213039
#
# Table name: shipments
#
#  id                        :integer         not null, primary key
#  box_id                    :integer
#  from_address_id           :integer
#  to_address_id             :integer
#  tracking_number           :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  shipment_label_file_name  :string(255)
#  shipment_label_updated_at :datetime
#  state                     :string(255)
#  order_id                  :integer
#  payor                     :string(255)
#

# Note: at this time there is no need for a shipment line, because we don't have the need to track shipment line items.
# If a shipment is associated with a box that means that the shipment is for the box.
# If a shipment is associated with an order that means it shipped one or more empty boxes. We only have the capability to ship
# entire order lines at this time.
class Shipment < ActiveRecord::Base
  require 'aws/s3'
  require 'soap/wsdlDriver'
  
  belongs_to :to_address, :class_name => "ShipmentAddress", :dependent => :destroy, :autosave => true
  belongs_to :from_address, :class_name => "ShipmentAddress", :dependent => :destroy, :autosave => true
  belongs_to :order
  belongs_to :box
  has_one :charge
  
  symbolize :state
  
  # state
  ACTIVE = :active
  INACTIVE = :inactive
  
  # payor
  CUSTOMER = :customer
  TVC = :tvc
    
  def Shipment.new()
    shipment = super
    shipment.state = ACTIVE
    shipment.payor = TVC
    shipment
  end
  
  def payor_english
    if payor == CUSTOMER
      return "Customer"
    elsif payor == TVC
      return "The Visible Closet"
    else
      return nil
    end
  end
  
  def payor
    return_val = read_attribute(:payor)
    if return_val.nil?
      return_val = TVC
    end
    
    return return_val
  end
  
  def Shipment.find_all_by_user_id(user_id, options = Hash.new)
    order_by = options[:order_by].nil? ? "" : options[:order_by]
    sql = "SELECT DISTINCT shipments.* FROM shipments, boxes, orders WHERE (shipments.box_id = boxes.id OR shipments.order_id = orders.id) AND boxes.assigned_to_user_id = #{user_id} AND orders.user_id = #{user_id} " + order_by
    find_by_sql(sql)
  end
  
  def user
    if self.order_id.nil?
      return self.box.nil? ? nil : self.box.user
    else
      return self.order.nil? ? nil : self.order.user
    end
  end
  
  def to_address_id=(value)
    write_attribute(:to_address_id, value)
    self.to_address = Address.find(value)
  end
  
  def to_address_with_extension=(value)
    target_attributes = value.attributes
    
    target_attributes["user_id"] = nil
    target_attributes.delete("created_at")
    target_attributes.delete("updated_at")
    
    # The convoluted check on address should never be needed, but is included just in case there's a data problem so we can never overwrite a customer's address info.
    if to_address.nil? || (!to_address.user.nil? || to_address_id == Rails.application.config.fedex_vc_address_id)
      self.to_address_without_extension = ShipmentAddress.new(target_attributes)
    else
      self.to_address.attributes = target_attributes
    end
  end
  
  alias_method_chain :to_address=, :extension

  # Allow errors if nil passed; should never be nil
  def from_address_id=(value)
    write_attribute(:from_address_id, value)
    self.from_address = Address.find(value)
  end
  
  def from_address_with_extension=(value)
    target_attributes = value.attributes
    
    target_attributes["user_id"] = nil
    target_attributes.delete("created_at")
    target_attributes.delete("updated_at")
    
    # The convoluted check on address should never be needed, but is included just in case there's a data problem so we can never overwrite a customer's address info.
    if from_address.nil? || (!from_address.user.nil? || from_address_id == Rails.application.config.fedex_vc_address_id)
      self.from_address_without_extension = ShipmentAddress.new(target_attributes)
    else
      self.from_address.attributes = target_attributes
    end
  end
  
  alias_method_chain :from_address=, :extension
  
  def generate_fedex_label(box = nil)
    if epl_label?
      label_stock_type = Fedex::LabelStockTypes::STOCK_4X6 # Fedex::LabelStockTypes::PAPER_4X6
      label_image_type = Fedex::LabelSpecificationImageTypes::EPL2
    else
      label_image_type = Rails.application.config.fedex_customer_label_image_type
    end
        
     fedex = Fedex::Base.new(basic_fedex_options.merge(
       :label_image_type => label_image_type,
       :label_stock_type => label_stock_type
     ))

     shipper = {
       :name => from_address.first_name + " " + from_address.last_name,
       :phone_number => from_address.day_phone
     }
     recipient = {
       :name => to_address.first_name + " " + to_address.last_name,
       :phone_number => to_address.day_phone
     }
     origin = {
       :street_lines => (from_address.address_line_2.blank? ? [from_address.address_line_1] : [from_address.address_line_1, from_address.address_line_2]),
       :city => from_address.city,
       :state => from_address.state,
       :zip => from_address.zip,
       :country => from_address.country
     }
    destination = {
      :street_lines => (to_address.address_line_2.blank? ? [to_address.address_line_1] : [to_address.address_line_1, to_address.address_line_2]),
      :city => to_address.city,
      :state => to_address.state,
     :zip => to_address.zip,
     :country => to_address.country,
     :residential => false
    }
    email_recipients = [{
      :email_address => from_address.user.nil? ? Rails.application.config.admin_email : from_address.user.email, 
      :type => Fedex::EMailNotificationRecipientTypes::SHIPPER
    },
    {
      :email_address => to_address.user.nil? ? Rails.application.config.admin_email : to_address.user.email, 
      :type => Fedex::EMailNotificationRecipientTypes::RECIPIENT
    }]
     
    
    pkg_count = 1
    weight = Rails.application.config.fedex_default_shipping_weight_lbs
    service_type = Fedex::ServiceTypes::FEDEX_GROUND
    if box # this is for a box
      customer_reference = "Box ##{self.box_id}"
      
      if box.box_type == Box::CUST_BOX_TYPE
        po_reference = "Check for inventorying: [  ]"
      else
        po_reference = nil
      end
    else
      customer_reference = nil
      po_reference = nil
    end

    self.shipment_label, self.tracking_number = fedex.label(
      :shipper => { :contact => shipper, :address => origin },
      :recipient => { :contact => recipient, :address => destination },
      :count => pkg_count,
      :weight => weight,
      :service_type => service_type,
      :customer_reference => customer_reference,
      :po_reference => po_reference,
      :update_emails => email_recipients
     )

     return save
  end
  
  def shipment_label=(file)
    if id.nil?
      raise "Cannot set label until shipment is saved."
    end

    # I believe if the connection is cached this does nothing
    AWS::S3::Base.establish_connection!(
        :access_key_id     => Rails.application.config.s3_key,
        :secret_access_key => Rails.application.config.s3_secret
    )
        
    self.shipment_label_file_name = Rails.application.config.s3_labels_path + "shipment_#{self.id}_label." + (epl_label? ? "epl" : "pdf")
    self.shipment_label_updated_at = Time.now
    
    if !(AWS::S3::S3Object.store(shipment_label_file_name, file, Rails.application.config.s3_labels_bucket) || !AWS::S3::Service.response.success?)
      raise "Unable to save file to AWS."
    end
  end
  
  def shipment_label(reload=false)
    # I believe if the connection is cached this does nothing
    AWS::S3::Base.establish_connection!(
        :access_key_id     => Rails.application.config.s3_key,
        :secret_access_key => Rails.application.config.s3_secret
    )

    if reload
      s3object = AWS::S3::S3Object.find(shipment_label_file_name, Rails.application.config.s3_labels_bucket)
      s3object.value(:reload)
    else
      s3object = AWS::S3::S3Object.value(shipment_label_file_name, Rails.application.config.s3_labels_bucket)
    end
  end
  
  def set_charge(amount)
    if !charge.nil?
      raise "Cannot reset charge for a shipment."
    end
    
    self.charge = Charge.create!(:user_id => user.id, :total_in_cents => amount*100, :shipment_id => id)
  end
  
  def shipment_label_file_name_short
    return_val = shipment_label_file_name
    return_val.slice! Rails.application.config.s3_labels_path
    
    return_val
  end
  
  def destroy
    # I believe if the connection is cached this does nothing
    AWS::S3::Base.establish_connection!(
        :access_key_id     => Rails.application.config.s3_key,
        :secret_access_key => Rails.application.config.s3_secret
    )

    if shipment_label_file_name
      AWS::S3::S3Object.delete(shipment_label_file_name, Rails.application.config.s3_labels_bucket)
    end
    
    cancel_fedex_shipment
    
    super
  end
  
  # this doesn't do anything right now because we don't need it yet
  def refresh_fedex_status
    # if tracking_number.blank?
    #   return false
    # end
    # 
    # fedex = Fedex::Base.new(basic_fedex_options)
    # 
    # results = fedex.get_latest_tracking_event(:tracking_number => tracking_number)
    # 
    # process_fedex_tracking_results
  end
  
  private
  
  def cancel_fedex_shipment
    if tracking_number.blank?
      return true
    end
    
    fedex = Fedex::Base.new(basic_fedex_options)
       
    # It's possible for each shipment that it's actually been shipped, in which case this code will cancel it.
    # If it has not been shipped then the FedEx system will return an error, which at most we want to log.
     if !fedex.cancel(:tracking_number => tracking_number)
       puts "Unable to cancel FedEx package identified by tracking number " + tracking_number
     end
  end
  
  def epl_label?
    return (box.nil? || box.status != Box::BEING_PREPARED_STATUS)
  end
  
  def basic_fedex_options
    { 
       :auth_key => Rails.application.config.fedex_auth_key,
       :security_code => Rails.application.config.fedex_security_code,
       :account_number => Rails.application.config.fedex_account_number,
       :meter_number => Rails.application.config.fedex_meter_number, 
       :debug => Rails.application.config.fedex_debug
     }
  end
end
