# == Schema Information
# Schema version: 20110705224828
#
# Table name: order_lines
#
#  id         :integer         not null, primary key
#  order_id   :integer
#  product_id :integer
#  quantity   :integer
#  status     :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class OrderLine < ActiveRecord::Base
  NEW_STATUS = "new"
  PROCESSED_STATUS = "processed"
  
  belongs_to :order
  belongs_to :product
  
  after_initialize :init_status
  
  def init_status
    if status.blank?
      self.status = NEW_STATUS
    end
  end
  
  def ship
    # bug checking
    if product_id != Rails.application.config.our_box_product_id
      raise "Error: order line being processed for shipping on non-shippable product"
    end
    
    self.status = PROCESSED_STATUS
    
    self.transaction do
      ordered_boxes.each do |box|
        box.status = Box::IN_TRANSIT_STATUS
        if (!box.save)
          raise "Unable to save box " << box.inspect
        end
      end
      
      if (!save)
        raise "Unable to save OrderLine " << self.inspect
      end
    end # end transaction
    
    return true # Only hard errors are thrown in the transaction, so if we made it here we are ok
  end
  
  def total_in_cents
    quantity * product.price * 100
  end
  
  def ordered_boxes
    Box.find_all_by_ordering_order_line_id(id)
  end
end
