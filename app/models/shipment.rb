# == Schema Information
# Schema version: 20110726022608
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
#

# Note: at this time there is no need for a shipment line, because we don't have the need to track shipment line items.
# If a shipment is associated with a box that means that the shipment is for the box.
# If a shipment is associated with an order that means it shipped one or more empty boxes. We only have the capability to ship
# entire order lines at this time.
class Shipment < ActiveRecord::Base
  require 'aws/s3'
  require 'soap/wsdlDriver'
  
  belongs_to :to_address, :class_name => "Address"
  belongs_to :from_address, :class_name => "Address"
  belongs_to :order
  belongs_to :box
  
  ACTIVE = :active
  INACTIVE = :inactive
    
  def Shipment.new()
    shipment = super
    shipment.state = ACTIVE
    shipment
  end
  
  def generate_fedex_label(box = nil)
    shipping_address = Address.find(self.from_address_id)
    receiving_address = Address.find(self.to_address_id)
    
    if epl_label?
      label_stock_type = Fedex::LabelStockTypes::STOCK_4X6 # Fedex::LabelStockTypes::PAPER_4X6
      label_image_type = Fedex::LabelSpecificationImageTypes::EPL2
    else
      label_image_type = Rails.application.config.fedex_customer_label_image_type
    end
        
     @fedex = Fedex::Base.new(
       :auth_key => Rails.application.config.fedex_auth_key,
       :security_code => Rails.application.config.fedex_security_code,
       :account_number => Rails.application.config.fedex_account_number,
       :meter_number => Rails.application.config.fedex_meter_number, 
       :debug => Rails.application.config.fedex_debug,
       :label_image_type => label_image_type,
       :label_stock_type => label_stock_type
     )

     shipper = {
       :name => shipping_address.first_name + " " + shipping_address.last_name,
       :phone_number => shipping_address.day_phone
     }
     recipient = {
       :name => receiving_address.first_name + " " + receiving_address.last_name,
       :phone_number => receiving_address.day_phone
     }
     origin = {
       :street_lines => (shipping_address.address_line_2.blank? ? [shipping_address.address_line_1] : [shipping_address.address_line_1, shipping_address.address_line_2]),
       :city => shipping_address.city,
       :state => shipping_address.state,
       :zip => shipping_address.zip,
       :country => shipping_address.country
     }
    destination = {
      :street_lines => (receiving_address.address_line_2.blank? ? [receiving_address.address_line_1] : [receiving_address.address_line_1, receiving_address.address_line_2]),
      :city => receiving_address.city,
      :state => receiving_address.state,
     :zip => receiving_address.zip,
     :country => receiving_address.country,
     :residential => false
    }
    email_recipients = [{
      :email_address => shipping_address.user.nil? ? Rails.application.config.admin_email : shipping_address.user.email, 
      :type => Fedex::EMailNotificationRecipientTypes::SHIPPER
    },
    {
      :email_address => receiving_address.user.nil? ? Rails.application.config.admin_email : receiving_address.user.email, 
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

    self.shipment_label, self.tracking_number = @fedex.label(
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
    
    super
  end
  
  private
  
  def epl_label?
    return (box.nil? || box.status != Box::BEING_PREPARED_STATUS)
  end
end
