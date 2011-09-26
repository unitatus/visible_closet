# == Schema Information
# Schema version: 20110924185624
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
#  return_requested_at        :datetime
#  location                   :string(255)
#

class Box < ActiveRecord::Base
  NEW_STATUS = "new"
  IN_TRANSIT_TO_YOU_STATUS = "in_transit_to_cust"
  IN_TRANSIT_TO_TVC_STATUS = "in_transit_to_tvc"
  IN_STORAGE_STATUS = "in_storage"
  BEING_PREPARED_STATUS = "being_prepared"
  RETURN_REQUESTED_STATUS = "return_requested"
  INACTIVE_STATUS = "inactive"
  
  NO_INVENTORYING_REQUESTED = "no_inventorying_requested"
  INVENTORYING_REQUESTED = "inventorying_requested"
  INVENTORIED = "inventoried"
  
  CUST_BOX_TYPE = "cust_box"
  VC_BOX_TYPE = "vc_box"
  
  attr_accessible :assigned_to_user_id, :ordering_order_line_id, :status, :box_type, :description, :inventorying_status, :subscription_id
  after_create :set_box_num

  has_many :stored_items, :dependent => :destroy
  has_many :shipments, :dependent => :destroy
  has_many :stored_item_tags, :through => :stored_items
  has_many :storage_charges, :order => "end_date DESC"
  has_one :servicing_order_line, :class_name => "OrderLine", :foreign_key => :service_box_id
  belongs_to :ordering_order_line, :class_name => "OrderLine"
  belongs_to :inventorying_order_line, :class_name => "OrderLine", :foreign_key => :inventorying_order_line_id
  belongs_to :user, :foreign_key => :assigned_to_user_id
  has_and_belongs_to_many :subscriptions
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
  
  def chargable?
    if never_received?
      return false
    else
      return never_requested_return? || storage_charges.size == 0 || return_requested_at > storage_charges.last.end_date
    end
  end
  
  # Sometimes object-oriented programming is really inefficient. This is one of those cases -- if we asked each box to calculate its cost, it would have to
  # figure out how many boxes were in storage on each day, and which ones were under a subscription at that time. Highly inefficient. This is a good case
  # to use array-based calculations, which is what we are doing here: we lay the boxes against the days in question to form a matrix, calculate and save things
  # in the matrix, then sum up by box to create the charges.
  def Box.calculate_charges_for_user_box_set(boxes, start_date, end_date)
    total_vc_boxes_in_storage_matrix = Hash[*boxes.select {|box| box.vc_box? }.collect {|box| [box, 0.0]}.flatten]
    total_cust_cf_in_storage_matrix = Hash[*boxes.select {|box| box.cust_box? }.collect {|box| [box, 0.0]}.flatten]
    box_events = Hash.new

    # In case where user has never had storage charge
    start_date = earliest_receipt_date(boxes)
    
    if start_date.nil? || start_date > end_date
      return []
    end

    # take care of datetime objects
    start_date = start_date.to_date
    end_date = end_date.to_date

    # Set up hash for ease of reading
    boxes.each do |box|
      box_events[box] = Array.new
    end
        
    (start_date + 1).upto(end_date) do |day|
      boxes.each do |box|
        # save total boxes / cf
        if box.vc_box? && box.in_storage_on(day)
          total_vc_boxes_in_storage_matrix[day] ||= 0
          total_vc_boxes_in_storage_matrix[day] += 1
        elsif box.cust_box? && box.in_storage_on(day)
          total_cust_cf_in_storage_matrix[day] ||= 0.0
          total_cust_cf_in_storage_matrix[day] += box.cubic_feet
        end
        
        # save whether anything changed, for informational purposes
        if day != (start_date + 1) && day != end_date
          if box.in_storage_on(day) && !box.in_storage_on(day - 1) && !box.charged_already_on(day)
            box_events[box] << "box receipt"
          end
          
          if box.in_storage_on(day) && !box.in_storage_on(day + 1) && !box.charged_already_on(day)
            box_events[box] << "box return"
          end
          
          if box.subscription_on(day) && box.subscription_on(day) != box.subscription_on(day - 1) && !box.charged_already_on(day)
            box_events[box] << "subscription number #{box.subscription_on(day).id} start"
          end
          
          if box.subscription_on(day) && box.subscription_on(day) != box.subscription_on(day + 1) && !box.charged_already_on(day)
            box_events[box] << "subscription number #{box.subscription_on(day).id} end"
          end
        end # end if on start and end dates of range
      end # end box_day_matrix keys loop
    end # end date range loop
    
    # now we know how many boxes / cf were in storage on each day. Time to calculate the charges by box.
    box_charges = Hash[*boxes.collect { |box| [box, 0.0] }.flatten]
    boxes.each do |box|
      (start_date + 1).upto(end_date) do |day|
        if box.in_storage_on(day) && !box.charged_already_on(day)
          subscription = box.subscription_on(day)
          subscription_months = subscription.nil? ? 0 : subscription.duration_in_months
        
          existing_product_count = box.vc_box? ? total_vc_boxes_in_storage_matrix[box] : total_cust_cf_in_storage_matrix[box]
        
          box_charges[box] += Discount.new(Box.get_product(box.box_type), 0, subscription_months, existing_product_count).unit_price_after_discount/days_in_month(day.month, day.year)
        end
      end
    end
    
    boxes.select { |box| box_charges[box] > 0.0 }.collect { |box|
      comments = "Storage charges"
      if !box_events[box].empty?
        comments += (" considering the following events in the period: " + box_events[box].join(", "))
      end
      
      new_charge = Charge.new(:total_in_cents => box_charges[box]*100, :comments => comments)
      new_charge.user = box.user
      new_storage_charge = StorageCharge.new(:start_date => start_date + 1, :end_date => end_date)
      new_charge.storage_charge = new_storage_charge
      new_storage_charge.charge = new_charge
      new_storage_charge.box = box
      
      new_charge
    }
  end
  
  def Box.earliest_receipt_date(boxes)
    earliest_receipt_date = nil
    
    boxes.each do |box|
      if !box.received_at.nil?
        earliest_receipt_date ||= box.received_at
        if earliest_receipt_date < box.received_at
          earliest_receipt_date = box.received_at
        end
      end
    end
    
    earliest_receipt_date
  end
  
  def subscription_on(date)
    # @subscriptions variable is for performance
    @date_subscriptions ||= Hash.new
    
    if @date_subscriptions[date]
      return @date_subscriptions[date]
    end
    
    matching_subscriptions = subscriptions.select { |subscription| !subscription.start_date.nil? \
                                && subscription.start_date <= date \
                                && ((!subscription.end_date.nil? && subscription.end_date >= date) \
                                    || (subscription.end_date.nil? && date <= subscription.start_date.to_time.advance(subscription.duration_in_months.months).to_date)) \
                         }

    @date_subscriptions[date] = matching_subscriptions.last
  end
  
  def charged_already_on(day)
    # Hash is for performance
    @days_already_charged ||= Hash.new
    
    if @days_already_charged[day]
      return true
    elsif !@days_already_charged[day].nil?
      return false
    end
    
    storage_charges.each do |storage_charge|
      if storage_charge.start_date <= day && storage_charge.end_date >= day
        @days_already_charged[day] = true and return
      end
    end
    
    @days_already_charged[day] = false and return
  end
  
  def current_subscription
    subscription_on(Date.today)
  end
  
  def in_storage_on(a_date)
    if never_received?
      return false
    else
      return received_at <= a_date && (never_requested_return? || return_requested_at >= a_date)
    end
  end
  
  def has_charges?
    self.storage_charges.size > 0
  end
  
  def never_received?
    received_at == nil
  end
  
  def never_requested_return?
    return_requested_at == nil
  end
  
  def vc_box?
    box_type == VC_BOX_TYPE
  end
  
  def cust_box?
    box_type == CUST_BOX_TYPE
  end
  
  def Box.get_type(product)
    if product.id == Rails.application.config.your_box_product_id
      CUST_BOX_TYPE
    elsif product.id == Rails.application.config.our_box_product_id
      VC_BOX_TYPE
    else
      nil
    end
  end
  
  def Box.get_product(type)
    if type == CUST_BOX_TYPE
      Product.find(Rails.application.config.your_box_product_id)
    elsif type == VC_BOX_TYPE
      Product.find(Rails.application.config.our_box_product_id)
    else
      nil
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
    if !subscription_on(Date.today).nil?
      subscription_on(Date.today).end_subscription
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
        
        subscription = self.current_subscription
        # the only way for the customer avoiding paying for a box coming in is if the box is on a subscription of sufficient duration
        if subscription.nil? || subscription.duration_in_months < Discount::FREE_SHIPPING_MONTH_THRESHOLD
          shipment.charge_requested = true
        end
      
        shipment.save
      end
      
      if !subscription.nil?
        subscription.start_subscription
      end
      
      return self.save
    end # end transaction
  end
  
  def create_shipment
    if self.id.nil?
      raise "Cannot create a shipment on a brand new box"
    end
    
    shipment = Shipment.new
    
    shipment.box_id = self.id
    shipment.from_address_id = get_shipping_from_address_id
    shipment.to_address_id = get_shipping_to_address_id
    
    if current_subscription.nil? || current_subscription.duration_in_months < Discount::FREE_SHIPPING_MONTH_THRESHOLD || self.status == RETURN_REQUESTED_STATUS 
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
  
  def current_subscription
    current_subscriptions = self.subscriptions.select { |subscription| subscription.start_date.nil? || subscription.start_date <= Date.today }
    if current_subscriptions.size == 0
      return nil
    elsif current_subscriptions.size > 1
      raise "Box has multiple subscriptions"
    else
      current_subscriptions.first
    end
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
    return Box.monthly_fee_for_type(self.user, self.box_type, self.cubic_feet, (self.current_subscription.nil? ? 1 : self.current_subscription.duration_in_months), self.inventorying_status)
  end
  
  # Added quantity is used for speculative pricing when the user is going through the check-out process
  def Box.monthly_fee_for_type(user, box_type, cubic_feet, subscription_duration, inventorying_status, added_quantity=0)
    # Box is not returned yet -- can't calculate fee
    if box_type == CUST_BOX_TYPE && cubic_feet.nil?
      return nil
    end
    
    if box_type == CUST_BOX_TYPE
      total_new_quantity = user.stored_cubic_feet_count + added_quantity * cubic_feet
      storage_product = Product.find(Rails.application.config.your_box_product_id)
      inventorying_product = Product.find(Rails.application.config.your_box_inventorying_product_id)
    else
      total_new_quantity = user.stored_box_count(box_type) + added_quantity
      storage_product = Product.find(Rails.application.config.our_box_product_id)
      inventorying_product = Product.find(Rails.application.config.our_box_inventorying_product_id)
    end
    
    storage_discount = Discount.new(storage_product, total_new_quantity, subscription_duration)
    
    if inventorying_status == NO_INVENTORYING_REQUESTED
      inventorying_fee = 0
    else
      inventorying_fee = Discount.new(inventorying_product, total_new_quantity, subscription_duration).unit_price_after_discount
    end
        
    if box_type == CUST_BOX_TYPE
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
    storage_charges.each do |storage_charge|
      storage_charge.charge.destroy # this will also take care of the storage charge
    end
    
    subscriptions.each do |subscription|
      if !subscription.nil? && subscription.boxes.size == 1
        subscription.destroy
        self.subscription = nil
      end
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
    active_shipments = Shipment.find_all_by_box_id_and_state(self.id, Shipment::ACTIVE, :order => "created_at DESC")
    
    active_shipments.first
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
  
  def Box.days_in_month(month, year)
    (Date.parse(year.to_s + "-" + month.to_s + "-01") - 1).day
  end
end
