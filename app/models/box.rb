# == Schema Information
# Schema version: 20110915215733
#
# Table name: boxes
#
#  id                         :integer         not null, primary key
#  assigned_to_user_id        :integer
#  created_at                 :datetime
#  updated_at                 :datetime
#  ordering_order_line_id     :integer
#  status                     :string(255)
#  box_type                   :string(255)
#  description                :text
#  inventorying_status        :string(255)
#  inventorying_order_line_id :integer
#  received_at                :datetime
#  height                     :float
#  width                      :float
#  length                     :float
#  weight                     :float
#  box_num                    :integer
#  subscription_id            :integer
#  return_requested_at        :datetime
#

class Box < ActiveRecord::Base
  NEW_STATUS = "new"
  IN_TRANSIT_TO_YOU_STATUS = "in_transit_to_cust"
  IN_TRANSIT_TO_TVC_STATUS = "in_transit_to_tvc"
  IN_STORAGE_STATUS = "in_storage"
  BEING_PREPARED_STATUS = "being_prepared"
  RETURN_REQUESTED_STATUS = "return_requested"
  
  NO_INVENTORYING_REQUESTED = "no_inventorying_requested"
  INVENTORYING_REQUESTED = "inventorying_requested"
  INVENTORIED = "inventoried"
  
  CUST_BOX_TYPE = "cust_box"
  VC_BOX_TYPE = "vc_box"
  
  attr_accessible :assigned_to_user_id, :ordering_order_line_id, :status, :box_type, :description, :inventorying_status, :subscription_id
  after_create :set_box_num

  has_many :stored_items, :dependent => :destroy
  has_many :shipments, :dependent => :destroy
  has_one :servicing_order_line, :class_name => "OrderLine", :foreign_key => :service_box_id
  belongs_to :ordering_order_line, :class_name => "OrderLine"
  belongs_to :inventorying_order_line, :class_name => "OrderLine", :foreign_key => :inventorying_order_line_id
  belongs_to :user, :foreign_key => :assigned_to_user_id
  belongs_to :subscription
  before_destroy :destroy_certain_parents
  
  # TODO: Figure out internationalization
  def status_en
    case status
    when NEW_STATUS
      return "New"
    when IN_TRANSIT_TO_YOU_STATUS
      return "In transit to you"
    when IN_TRANSIT_TO_TVC_STATUS
      return "In transit to us"
    when IN_STORAGE_STATUS
      return "In Storage"
    when BEING_PREPARED_STATUS
      return "Being prepared by you"
    when RETURN_REQUESTED_STATUS
      return "Return requested"
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

  # Want to make sure we don't get any data errors.
  def height
    if self.box_type == Box::VC_BOX_TYPE
      return Rails.application.config.vc_box_height
    end
    return read_attribute(:height)
  end

  # Want to make sure we don't get any data errors.
  def width
    if self.box_type == Box::VC_BOX_TYPE
      return Rails.application.config.vc_box_width
    end
    
    return read_attribute(:width)
  end

  # Want to make sure we don't get any data errors.
  def length
    if self.box_type == Box::VC_BOX_TYPE
      return Rails.application.config.vc_box_length
    end
    return read_attribute(:length)
  end
  
  def ordering_order
    ordering_order_line.order
  end
  
  def mark_for_return
    update_attribute(:status, RETURN_REQUESTED_STATUS)
    update_attribute(:return_requested_at, Time.now)
    if !subscription.nil?
      subscription.end_subscription
    end
  end
  
  def inventorying_order
    if inventorying_order_line.nil?
      return nil
    else
      return inventorying_order_line.order
    end
  end
  
  def servicing_order
    if servicing_order_line.nil?
      return nil
    else
      return servicing_order_line.order
    end
  end
  
  def receive(inventorying_requested = false)
    self.transaction do
      
      # need to check for both, since one disables the other which means that it is not posted
      if inventorying_requested
        # this check exists to ensure that customers are not double-charged if we restart the inventorying process. You only get the inventorying order
        # if you move from "no inventorying requested" to "inventorying requested"
        if self.inventorying_status == Box::NO_INVENTORYING_REQUESTED
          generate_inventorying_order
        end
        self.inventorying_status = Box::INVENTORYING_REQUESTED
      end
    
      self.status = Box::IN_STORAGE_STATUS
      self.received_at = Time.now
      
      shipment = self.active_shipment
      
      # This if check is to allow for multiple receiving of the same box, in case an error was made.
      if !shipment.nil?
        shipment.state = Shipment::DELIVERED
        # the only way for the customer avoiding paying for a box coming in is if the box is on a subscription of sufficient duration
        if self.subscription.nil? || self.subscription.duration_in_months < Discount::FREE_SHIPPING_MONTH_THRESHOLD
          shipment.charge_requested = true
        end
      
        shipment.save
      end
      
      if !subscription.nil?
        self.subscription.start_subscription
      end
      
      return self.save
    end # end transaction
  end
  
  def create_shipment
    if self.id.nil?
      raise "Cannot create a shipment on a brand new box"
    end
    
    if !self.active_shipment.nil?
      raise "This box has a shipment that was never processed."
    end
    
    shipment = Shipment.new
    
    shipment.box_id = self.id
    shipment.from_address_id = get_shipping_from_address_id
    shipment.to_address_id = get_shipping_to_address_id
    
    if subscription.nil? || subscription.duration_in_months < Discount::FREE_SHIPPING_MONTH_THRESHOLD || self.status == RETURN_REQUESTED_STATUS 
      shipment.payor = Shipment::CUSTOMER
    end

    if (!shipment.save)
      raise "Malformed data: cannot save shipment; error: " << shipment.errors.inspect
    end
    
    begin
      if !shipment.generate_fedex_label(self)
        shipment.destroy
        raise "Malformed data: cannot save shipment; error: " << shipment.errors.inspect
      end
    rescue Exception => e
      shipment.destroy
      raise e
    end
    
    shipment
  end
  
  def ship
    if (self.status == NEW_STATUS && self.box_type == VC_BOX_TYPE) || (self.status == RETURN_REQUESTED_STATUS)
      shipment = create_shipment
      self.update_attribute(:status, Box::IN_TRANSIT_TO_YOU_STATUS)
      return shipment
    else
      raise "Attempted to ship in invalid status, for box " << self.inspect
    end
  end
  
  def Box.find_by_ordering_order_lines(order_lines)
    Box.where(:ordering_order_line_id => convert_to_id_array(order_lines))
  end
  
  def Box.find_by_service_order_lines(order_lines)
    Box.joins(:servicing_order_line).where('order_lines.id' => convert_to_id_array(order_lines)).all
  end
  
  def monthly_fee
    # Box is not returned yet -- can't calculate fee
    if self.box_type == CUST_BOX_TYPE && cubic_feet.nil?
      return nil
    end
    
    if self.box_type == CUST_BOX_TYPE
      storage_product = Product.find(Rails.application.config.your_box_product_id)
      inventorying_product = Product.find(Rails.application.config.your_box_inventorying_product_id)
    else
      storage_product = Product.find(Rails.application.config.our_box_product_id)
      inventorying_product = Product.find(Rails.application.config.our_box_inventorying_product_id)
    end
    
    box_count_like_me = Box.count_boxes(self.user, self.status, self.box_type)
    storage_discount = Discount.new(storage_product, box_count_like_me, (subscription.nil? ? 1 : subscription.duration_in_months))
    
    if self.inventorying_status == NO_INVENTORYING_REQUESTED
      inventorying_fee = 0
    else
      inventorying_fee = Discount.new(inventorying_product, box_count_like_me, (subscription.nil? ? 1 : subscription.duration_in_months)).unit_price_after_discount
    end
        
    if self.box_type == CUST_BOX_TYPE
      return (storage_discount.unit_price_after_discount + inventorying_fee) * cubic_feet
    else
      return storage_discount.unit_price_after_discount + inventorying_fee
    end
  end
  
  def cubic_feet
    if self.length.nil? || self.width.nil? || self.height.nil?
      return nil
    else
      divisor = Rails.application.config.box_dimension_divisor
      return (self.length/divisor) * (self.width/divisor) * (self.height/divisor)
    end
  end
  
  def Box.count_boxes(user, status=nil, type=nil)
    conditions = {:conditions => "assigned_to_user_id = #{user.id}"}
    
    if status
      conditions[:conditions] << " AND status = '#{status}'"
    end
    
    if type
      conditions[:conditions] << " AND box_type = '#{type}'"
    end
    
    Box.count(conditions)
  end
  
  def item_count
    StoredItem.count(:conditions => "box_id = #{self.id}")
  end
  
  # Called before destroy; destroys related subscriptions if this is the last box in the subscription
  def destroy_certain_parents
    if !subscription.nil? && subscription.boxes.size == 1
      subscription.destroy
      self.subscription = nil
    end
    
    if !inventorying_order_line.nil?
      order = inventorying_order_line.order
      
      if order.order_lines.size == 1 # this is the last line
        order.destroy
      else
        the_line.destroy
      end
    end
  end
  
  def active_shipment
    active_shipments = Shipment.find_all_by_box_id_and_state(self.id, Shipment::ACTIVE)
    
    if active_shipments.size > 1
      raise "Improper process flow: somehow a box has multiple active shipments."
    else
      active_shipments[0]
    end
  end
  
  private
  
  def Box.convert_to_id_array(objects)
    object_ids = Array.new
    
    objects.each do |object|
      object_ids << object.id
    end
    
    object_ids
  end
    
  def get_shipping_from_address_id
    if self.status == BEING_PREPARED_STATUS && self.box_type == CUST_BOX_TYPE # we are generating the shipment to send in the box for the first time
      self.ordering_order_line.shipping_address_id
    elsif self.status == NEW_STATUS && self.box_type == VC_BOX_TYPE # we are generating the shipment to send in the vc box for the first time
      self.ordering_order_line.shipping_address_id
    elsif self.status = RETURN_REQUESTED_STATUS # we are returning the box to the customer
      Rails.application.config.fedex_vc_address_id
    else
      raise "Unimplemented box state for shipping"
    end    
  end
  
  def get_shipping_to_address_id
    if self.status == BEING_PREPARED_STATUS && self.box_type == CUST_BOX_TYPE    
      Rails.application.config.fedex_vc_address_id
    elsif self.status == NEW_STATUS && self.box_type == VC_BOX_TYPE
      Rails.application.config.fedex_vc_address_id
    elsif self.status = RETURN_REQUESTED_STATUS
      self.servicing_order_line.shipping_address_id
    else
      raise "Unimplemented box state for shipping"
    end
  end
  
  def generate_inventorying_order
    if self.box_type == CUST_BOX_TYPE
      product_id = Rails.application.config.your_box_inventorying_product_id
    elsif self.box_type == VC_BOX_TYPE
      product_id = Rails.application.config.our_box_inventorying_product_id
    else
      raise "Invalid box type for box " << inspect
    end
    
    ordering_line = OrderLine.find(self.ordering_order_line_id)
    
    order = Order.new
    
    order.user_id = assigned_to_user_id
    
    if (!order.save)
      raise "Failed to save order; messages: " << order.errors.full_messages.inspect
    end
    
    order_line = OrderLine.new
    
    order_line.product_id = product_id
    order_line.order_id = order.id
    order_line.quantity = 1
    order_line.committed_months = ordering_line.committed_months.nil? ? 0 : ordering_line.committed_months
    
    if (!order_line.save)
      raise "Failed to save order line " + order_line.inspect + " for box " + inspect
    else
      self.inventorying_order_line_id = order_line.id
    end
    
    order.generate_charges
  end
  
  def set_box_num
    update_attribute(:box_num, self.user.next_box_num)
  end
end
