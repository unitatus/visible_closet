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
  
  ACTIVE = :active
  INACTIVE = :inactive
    
  def Shipment.new()
    shipment = super
    shipment.state = ACTIVE
    shipment
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
