# == Schema Information
# Schema version: 20110706050041
#
# Table name: boxes
#
#  id                  :integer         not null, primary key
#  assigned_to_user_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#  order_line_id       :integer
#  status              :string(255)
#  insured             :boolean
#  box_type            :string(255)
#

class Box < ActiveRecord::Base
  NEW_STATUS = :new
  IN_TRANSIT_STATUS = :in_transit
  IN_STORAGE_STATUS = :in_storage
  
  CUST_BOX_TYPE = :cust_box
  VC_BOX_TYPE = :vc_box
  
  attr_accessible :assigned_to_user_id, :order_line_id, :status, :box_type, :insured

  has_many :stored_items
  has_one :order_line
end
