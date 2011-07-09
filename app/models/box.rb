# == Schema Information
# Schema version: 20110709182101
#
# Table name: boxes
#
#  id                  :integer         not null, primary key
#  assigned_to_user_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#  order_line_id       :integer
#  status              :string(255)
#  box_type            :string(255)
#  description         :text
#  indexing_status     :string(255)
#

class Box < ActiveRecord::Base
  NEW_STATUS = "new"
  IN_TRANSIT_STATUS = "in_transit"
  IN_STORAGE_STATUS = "in_storage"
  BEING_PREPARED_STATUS = "being_prepared"
  
  NO_INDEXING_REQUESTED = "no_indexing_requested"
  INDEXING_REQUESTED = "indexing_requested"
  INDEXED = "indexed"
  
  # TODO: Get rid of these, turn them into strings
  CUST_BOX_TYPE = "cust_box"
  VC_BOX_TYPE = "vc_box"
  
  attr_accessible :assigned_to_user_id, :order_line_id, :status, :box_type, :description, :indexing_status

  has_many :stored_items
  has_one :order_line
  
  # TODO: Figure out internationalization
  def status_en
    case status
    when NEW_STATUS
      return "New"
    when IN_TRANSIT_STATUS
      return "In Transit"
    when IN_STORAGE_STATUS
      return "In Storage"
    when BEING_PREPARED_STATUS
      return "Being prepared by you"
    else
      raise "Illegal status " << status
    end
  end
  
  def box_type_en
    case box_type
    when CUST_BOX_TYPE
      return "Box provided by you"
    when VC_BOX_TYPE
      return "Box provided by The Visible Closet"
    else
      raise "Illegal box type " << box_type
    end
  end
  
  def receive(indexing_requested = false)
    # need to check for both, since one disables the other which means that it is not posted
    if indexing_requested
      if self.indexing_status == Box::NO_INDEXING_REQUESTED
        generate_indexing_order
      end
      self.indexing_status = Box::INDEXING_REQUESTED
    end
    
    self.status = Box::IN_STORAGE_STATUS
    
    self.transaction do
      generate_indexing_order
      
      return self.save
    end
  end
  
  private
  
  def generate_indexing_order
    if self.box_type == CUST_BOX_TYPE
      product_id = Rails.application.config.your_box_inventorying_product_id
    elsif self.box_type == VC_BOX_TYPE
      product_id = Rails.application.config.our_box_inventorying_product_id
    else
      raise "Invalid box type for box " << inspect
    end
    
    order = InternalOrder.new
    
    order.user_id = assigned_to_user_id
    
    if (!order.save)
      raise "Failed to save order; messages: " << order.errors.full_messages.inspect
    end
    
    order_line = OrderLine.new
    
    order_line.product_id = product_id
    order_line.order_id = order.id
    order_line.quantity = 1
    
    if (!order_line.save)
      raise "Failed to save order line " + order_line.inspect + " for box " + inspect
    end
    
    order.generate_charges
  end
end
