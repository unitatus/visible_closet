# == Schema Information
# Schema version: 20110913230417
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
#  shipment_id         :integer
#

class OrderLine < ActiveRecord::Base
  NEW_STATUS = "new"
  PROCESSED_STATUS = "processed"
  
  belongs_to :order
  belongs_to :product
  belongs_to :shipping_address, :class_name => 'Address'
  belongs_to :service_box, :class_name => 'Box'
  belongs_to :shipment
  has_many :ordered_boxes, :class_name => 'Box', :foreign_key => :ordering_order_line_id, :dependent => :destroy
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
    if product_id != Rails.application.config.our_box_product_id && product_id != Rails.application.config.return_box_product_id
      raise "Error: order line being processed for shipping on non-shippable product"
    end
    
    self.status = PROCESSED_STATUS
    
    self.transaction do
      
      associated_boxes.each do |box|
        box_shipment = box.ship # the box will check its state and behave accordingly; new boxes will have their shipment back to us generated; returned boxes will have their outgoing shipment created
        
        if box_shipment.nil?
          raise "Unable to ship box; errors " << box.errors.inspect
        elsif self.product_id == Rails.application.config.return_box_product_id
          update_attribute(:shipment_id, box.active_shipment.id)
        end
      end
      
      if ordered_boxes.size > 0 # must generate shipment for shipping materials. This can only happen once per order.
        supplies_shipment = Shipment.new
        
        supplies_shipment.from_address_id = Rails.application.config.fedex_vc_address_id
        supplies_shipment.to_address_id = self.shipping_address_id
      
        if !supplies_shipment.save
          raise "Error saving shipment; errors: " << order_shipment.errors.inspect
        end    
      
        if !supplies_shipment.generate_fedex_label
          raise "Error generating shipment and saving; errors: " << order_shipment.errors.inspect
        end
        
        update_attribute(:shipment_id, supplies_shipment.id)
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
    # don't need to worry about the products on this order, because they would never be in storage if we are looking at the discount for the order
    Discount.new(product, quantity, committed_months, self.cust_box? ? order.user.stored_cubic_feet_count : order.user.stored_box_count(Box.get_type(product)))
  end
  
  def cust_box?
    product_id == Rails.application.config.your_box_product_id
  end
  
  def vc_box?
    product_id == Rails.application.config.our_box_product_id
  end
  
  def unit_price_after_discount
    self.discount.unit_price_after_discount
  end
  
  def associated_boxes
    all_boxes = Array.new
    # since ruby does pass by reference, we have to be careful about making a separate copy of the array, otherwise adding the return box to the ordered box array will make the return box an ordered box!
    all_boxes = all_boxes | ordered_boxes
    returned_box = service_box
    if returned_box
      all_boxes << returned_box # the bug is here. Rails seems to think that all_boxes is the ordered_boxes array, so adding this to the array makes the returned box an ordered box. WTF. Hello pass by value?
    end
    
    all_boxes
  end
  
  def inventorying_line?
    product_id == Rails.application.config.our_box_inventorying_product_id || product_id == Rails.application.config.your_box_inventorying_product_id
  end
  
  def box_order_line?
    product_id == Rails.application.config.our_box_product_id || product_id == Rails.application.config.your_box_product_id
  end
  
  def return_order_line?
    product_id == Rails.application.config.return_box_product_id
  end
  
  def OrderLine.total_quantity(order_lines)
    total_quantity = 0
    
    order_lines.each do |line|
      total_quantity += line.quantity
    end
    
    total_quantity
  end
  
  def associated_boxes
    all_boxes = ordered_boxes | inventoried_boxes
    all_boxes << service_box if service_box
    all_boxes
  end
  
  private
  
  def dissociate_inventoried_boxes
    inventoried_boxes.each do |box|
      box.update_attribute(:inventorying_order_line_id, nil)
    end
  end
end
