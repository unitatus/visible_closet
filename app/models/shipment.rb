# == Schema Information
# Schema version: 20110724155803
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
#

class Shipment < ActiveRecord::Base
  require 'aws/s3'
  require 'soap/wsdlDriver'
  
  ACTIVE = :active
  INACTIVE = :inactive
    
  def Shipment.new()
    shipment = super
    shipment.state = ACTIVE
    shipment
  end
  
  def generate_fedex_label(box)
    shipping_address = Address.find(self.from_address_id)
    receiving_address = Address.find(self.to_address_id)
    
    if box.status != Box::BEING_PREPARED_STATUS
      label_stock_type = Fedex::LabelStockTypes::PAPER_4X6
    end
        
     @fedex = Fedex::Base.new(
       :auth_key => Rails.application.config.fedex_auth_key,
       :security_code => Rails.application.config.fedex_security_code,
       :account_number => Rails.application.config.fedex_account_number,
       :meter_number => Rails.application.config.fedex_meter_number, 
       :debug => Rails.application.config.fedex_debug,
       :label_image_type => Rails.application.config.fedex_customer_label_image_type,
       :label_stock_type => label_stock_type
     )

     shipper = {
       :name => shipping_address.first_name + " " + shipping_address.last_name,
       :phone_number => shipping_address.day_phone
     }
     recipient = {
       :name => Rails.application.config.fedex_vc_name,
       :phone_number => receiving_address.day_phone
     }
     origin = {
       :street => shipping_address.address_line_1 + (shipping_address.address_line_2.nil? ? "" : " " + shipping_address.address_line_2),
       :city => shipping_address.city,
       :state => shipping_address.state,
       :zip => shipping_address.zip,
       :country => shipping_address.country
     }
    destination = {
      :street => receiving_address.address_line_1 + (receiving_address.address_line_2.nil? ? "" : " " + receiving_address.address_line_2),
      :city => receiving_address.city,
      :state => receiving_address.state,
     :zip => receiving_address.zip,
     :country => receiving_address.country,
     :residential => false
    }
    pkg_count = 1
    weight = Rails.application.config.fedex_default_shipping_weight_lbs
    service_type = Fedex::ServiceTypes::FEDEX_GROUND
    customer_reference = "Box ##{self.box_id}"
    po_reference = "Check for inventorying: [  ]"

    self.shipment_label, self.tracking_number = @fedex.label(
      :shipper => { :contact => shipper, :address => origin },
      :recipient => { :contact => recipient, :address => destination },
      :count => pkg_count,
      :weight => weight,
      :service_type => service_type,
      :customer_reference => customer_reference,
      :po_reference => po_reference
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
        
    self.shipment_label_file_name = Rails.application.config.s3_labels_path + "shipment_#{self.id}_label.pdf"
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
end
