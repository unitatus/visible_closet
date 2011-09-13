# == Schema Information
# Schema version: 20110913042727
#
# Table name: order_lines
#
#  id                  :integer         not null, primary key
#  order_id            :integer
#  product_id          :integer
#  quantity            :integer
#  status              :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  committed_months    :integer
#  shipping_address_id :integer
#  service_box_id      :integer
#

class OrderLine < ActiveRecord::Base
  NEW_STATUS = "new"
  PROCESSED_STATUS = "processed"
  
  belongs_to :order
  belongs_to :product
  belongs_to :shipping_address, :class_name => 'Address'
  belongs_to :service_box, :class_name => 'Box'
  has_many :boxes, :foreign_key => :ordering_order_line_id, :dependent => :destroy
  has_many :inventoried_boxes, :foreign_key => :inventorying_order_line_id, :class_name => "Box"
  
  after_initialize :init_status
  before_destroy :dissociate_inventoried_boxes
  
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
        if (!box.ship)
          raise "Unable to ship box; errors " << box.errors.inspect
        end
      end
      
      if (!save)
        raise "Unable to save OrderLine " << self.inspect
      end
    end # end transaction
    
    return true # Only hard errors are thrown in the transaction, so if we made it here we are ok
  end
  
  def total_in_cents
    self.unit_price_after_discount*self.quantity*100
  end
  
  def discount
    Discount.new(product, quantity, committed_months)
  end
  
  def unit_price_after_discount
    self.discount.unit_price_after_discount
  end
  
  def ordered_boxes
    Box.find_all_by_ordering_order_line_id(id)
  end
  
  def inventorying_line
    product_id == Rails.application.config.our_box_inventorying_product_id || product_id == Rails.application.config.your_box_inventorying_product_id
  end
  
  def OrderLine.total_quantity(order_lines)
    total_quantity = 0
    
    order_lines.each do |line|
      total_quantity += line.quantity
    end
    
    total_quantity
  end
  
  private
  
  def dissociate_inventoried_boxes
    inventoried_boxes.each do |box|
      box.update_attribute(:inventorying_order_line_id, nil)
    end
  end
end
