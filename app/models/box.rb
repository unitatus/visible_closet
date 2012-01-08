# == Schema Information
# Schema version: 20120108183638
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
#  weight                     :float
#  box_num                    :integer
#  return_requested_at        :datetime
#  inventoried_at             :datetime
#  created_by_id              :integer
#

class Box < ActiveRecord::Base
  include HasDimensions
  
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
  
  attr_accessible :assigned_to_user_id, :ordering_order_line_id, :status, :box_type, :description, :inventorying_status, :subscription_id, :height, :weight, :width, :length, :location, :created_by_id
  after_create :set_box_num

  has_many :stored_items, :dependent => :destroy
  has_many :shipments, :dependent => :destroy, :order => "created_at ASC"
  has_many :stored_item_tags, :through => :stored_items
  has_many :storage_charges, :order => "end_date ASC" # This way .first means the first ever charge, and .last means the last ever storage charge, by end_date
  has_one :servicing_order_line, :class_name => "OrderLine", :foreign_key => :service_box_id
  belongs_to :ordering_order_line, :class_name => "OrderLine"
  belongs_to :inventorying_order_line, :class_name => "OrderLine", :foreign_key => :inventorying_order_line_id
  belongs_to :user, :foreign_key => :assigned_to_user_id
  belongs_to :created_by, :class_name => "User"
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
      return never_requested_return? || storage_charges.size == 0 || storage_charges.last.end_date.nil? || return_requested_at > storage_charges.last.end_date
    end
  end
  
  # the idea behind this is to return the day before when we should start charging
  def latest_charge_end_date
    if storage_charges.size == 0 || storage_charges.last.end_date.nil?
      return received_at.to_date - 1
    else
      return storage_charges.last.end_date.to_date
    end
  end
  
  # Sometimes object-oriented programming is really inefficient. This is one of those cases -- if we asked each box to calculate its cost, it would have to
  # figure out how many boxes were in storage on each day, and which ones were under a subscription at that time. Highly inefficient. This is a good case
  # to use array-based calculations, which is what we are doing here: we lay the boxes against the days in question to form a matrix, calculate and save things
  # in the matrix, then sum up by box to create the charges.
  def Box.calculate_charges_for_user_box_set(user, start_date, end_date, save=false)
    total_vc_boxes_in_storage_by_day = Hash.new
    total_cust_cf_in_storage_by_day = Hash.new
    box_events = Hash.new
    boxes = user.boxes

    # In case where user has never had storage charge
    start_date ||= earliest_receipt_date(boxes)
    
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
        
    start_date.upto(end_date) do |day|
      boxes.each do |box|
        # save total boxes / cf
        if box.vc_box? && box.in_storage_on(day)
          total_vc_boxes_in_storage_by_day[day] ||= 0
          total_vc_boxes_in_storage_by_day[day] += 1
        elsif box.cust_box? && box.in_storage_on(day)
          total_cust_cf_in_storage_by_day[day] ||= 0.0
          total_cust_cf_in_storage_by_day[day] += box.cubic_feet
        end
        
        # save whether anything changed, for informational purposes
        if day != start_date
          if box.in_storage_on(day) && !box.in_storage_on(day - 1) && !box.charged_already_on(day)
            box_events[box] << "receipt on " + day.strftime("%m/%d/%Y")
          end

          if box.subscription_on(day) && box.subscription_on(day) != box.subscription_on(day - 1) && !box.charged_already_on(day)
            box_events[box] << "subscription start on " + day.strftime("%m/%d/%Y")
          end          
        end
          
        if day != end_date
          if box.in_storage_on(day) && !box.in_storage_on(day + 1) && !box.charged_already_on(day)
            box_events[box] << "return on " + day.strftime("%m/%d/%Y")
          end
          
          if box.subscription_on(day) && box.subscription_on(day) != box.subscription_on(day + 1) && !box.charged_already_on(day)
            box_events[box] << "subscription end on " + day.strftime("%m/%d/%Y")
          end
        end
      end # end box_day_matrix keys loop
    end # end date range loop

    # now we know how many boxes / cf were in storage on each day. Time to calculate the charges by box.
    box_charges = Hash[*boxes.collect { |box| [box, Rational(0)] }.flatten]
    boxes.each do |box|
      start_date.upto(end_date) do |day|
        if box.in_storage_on(day) && !box.charged_already_on(day)

          subscription = box.subscription_on(day)
          subscription_months = subscription.nil? ? 0 : subscription.duration_in_months
        
          existing_product_count = box.vc_box? ? total_vc_boxes_in_storage_by_day[day] : total_cust_cf_in_storage_by_day[day]
          
          storage_discount_calc = Discount.new(Box.get_product(box.box_type), 0, subscription_months, existing_product_count)
          
          units = box.vc_box? ? 1 : box.cubic_feet
          box_charges[box] += Rational(storage_discount_calc.unit_price_after_discount*units, days_in_month(day.month, day.year))

          if box.inventoried_on(day)
            inventory_discount_calc = Discount.new(Box.get_product(box.box_type, true), 0, subscription_months, existing_product_count)
            box_charges[box] += Rational(inventory_discount_calc.unit_price_after_discount*units, days_in_month(day.month, day.year))
          end
        end
      end
    end

    boxes.select { |box| box_charges[box] > 0.0 }.collect { |box|
      comments = "Storage charges for box " + box.box_num.to_s
      if !box_events[box].empty?
        comments += (" (prorated for " + box_events[box].join(", ") + ")")
      end
      
      # This is a bit asinine. If we were to build the charge on the box's user object, then any other references to user won't get the update until we save.
      # Thus, in the case where we want to calculate the charges for a customer without saving them, we must pass in that customer's object (user) and associate
      # the charges with that object here. Thus, if we said user.charges we'd get this charge, but if said user.boxes[0].charges we would not! Bizarre.
      new_charge = user.charges.build(:comments => comments)
      new_charge.total_in_cents = (box_charges[box].to_f*100.0).round
            
      new_charge.associate_with(box, start_date, end_date)
      
      if (save)
        new_charge.save
      end
      
      new_charge
    }
  end
  
  def Box.print_out_box_charges(box_charges)
    box_charges.keys.each do |box|
      puts "Box #" + box.id.to_s + ": " + box_charges[box].to_f.to_s
    end
  end
  
  def Box.earliest_receipt_date(boxes)
    earliest_receipt_date = nil
    
    boxes.each do |box|
      if box.received_at
        earliest_receipt_date ||= box.received_at
        if earliest_receipt_date < box.received_at
          earliest_receipt_date = box.received_at
        end
      end
    end
    
    earliest_receipt_date
  end
  
  def Box.batch_create_boxes(user, box_type, submitted_info, creator)
    created_boxes = Array.new
    
    submitted_info.each do |submitted_box_info|
      options = Hash.new.merge(submitted_box_info)
      options[:box_type] = box_type
      options[:created_by_id] = creator.id
      created_box = create_box!(user, options)
      if created_box.nil?
        raise "Failed to create a box!"
      end
      
      created_box.receive(submitted_box_info[:inventory_requested])
      
      created_boxes << created_box
    end
    
    return created_boxes
  end
  
  # Must pass either box_type or product in options
  def Box.create_box!(owner, options)
    if options[:committed_months].nil? || options[:committed_months] == 0
      subscription = nil
    else
      subscription = Subscription.create!(:duration_in_months => options[:committed_months], :user_id => owner.id)
    end
    
    box_type = options[:box_type]
    if box_type.nil?
      box_type = options[:product].vc_box? ? Box::VC_BOX_TYPE : Box::CUST_BOX_TYPE
    end

    if box_type == Box::VC_BOX_TYPE
      status = Box::NEW_STATUS
    else
      status = Box::BEING_PREPARED_STATUS
    end
    
    new_box = create!(:assigned_to_user_id => owner.id, 
                      :ordering_order_line_id => options[:ordering_order_line_id], 
                      :status => status,
                      :box_type => box_type,
                      :inventorying_status => Box::NO_INVENTORYING_REQUESTED, # Boxes are always created this way; you have to switch inventorying on after creation as part of receiving
                      :height => options[:height],
                      :width => options[:width],
                      :length => options[:length],
                      :weight => options[:weight],
                      :description => options[:description],
                      :location => options[:location],
                      :created_by_id => options[:created_by_id])
    
    new_box.subscriptions << subscription if subscription
    
    return new_box
  end
  
  def extra_inventorying_cost
    if inventorying_status != NO_INVENTORYING_REQUESTED
      return 0.0
    end
    
    product = Box.get_product(box_type, true)
    new_product_count = 0
    subscription = current_subscription
    month_count = subscription.nil? ? 0 : subscription.duration_in_months
    product_count = user.box_count(box_type)
    
    unit_discount_amt = Discount.new(product, new_product_count, month_count, product_count).unit_price_after_discount
    
    if box_type == VC_BOX_TYPE
      return unit_discount_amt
    else
      return unit_discount_amt * cubic_feet
    end
  end
  
  def subscription_on(date)
    subscriptions.select { |subscription| subscription.applies_on(date) }.last
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
      if storage_charge.start_date && storage_charge.start_date <= day && storage_charge.end_date >= day
        @days_already_charged[day] = true and return true
      end
    end
    
    @days_already_charged[day] = false and return false
  end
  
  def current_subscription
    subscription_on(Date.today)
  end
  
  def in_storage_on(a_date)
    if never_received?
      return false
    else
      return received_at.to_date <= a_date && (never_requested_return? || return_requested_at.to_date >= a_date)
    end
  end
  
  def inventoried_on(a_date)
    if never_inventoried?
      return false
    else
      return inventoried_at.to_date <= a_date && (never_requested_return? || return_requested_at.to_date >= a_date)
    end
  end
  
  def never_inventoried?
    return inventoried_at.nil?
  end
  
  def inventory_requested?
    inventorying_status == INVENTORYING_REQUESTED
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
  
  def Box.get_product(type, inventory=false)
    if type == CUST_BOX_TYPE && inventory
      Product.find(Rails.application.config.your_box_inventorying_product_id)
    elsif type == CUST_BOX_TYPE
      Product.find(Rails.application.config.your_box_product_id)
    elsif type == VC_BOX_TYPE && inventory
      Product.find(Rails.application.config.our_box_inventorying_product_id)
    elsif type == VC_BOX_TYPE
      Product.find(Rails.application.config.our_box_product_id)
    elsif 
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
    ordering_order_line.nil? ? nil : ordering_order_line.order
  end
  
  # this is only called when the user submits the order for a return; when they mark a box for a return, it just goes in the cart!
  def mark_for_return
    update_attribute(:status, RETURN_REQUESTED_STATUS)
    update_attribute(:return_requested_at, Time.now)
    if !subscription_on(Date.today).nil?
      # TODO: This is wrong. you should not be able to do this.
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
  
  def in_storage?
    self.status == Box::IN_STORAGE_STATUS
  end
  
  def receive(inventorying_requested = false)
    self.transaction do
      
      # This must happen first, as other processing checks the box's status
      self.status = Box::IN_STORAGE_STATUS
      self.received_at = Time.now

      if inventorying_requested
        process_inventory_request
      end
      
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
      
      if !current_subscription.nil?
        current_subscription.start_subscription
      end
            
      return self.save
    end # end transaction
  end
  
  # The very first shipment for a box is the shipment that sends it to The Visible Closet
    def first_or_create_shipment
      first_shipment = self.shipments.first

      if first_shipment.nil?
        create_shipment
      else
        first_shipment
      end
    end

  def process_inventory_request(send_admin_email=false)
    # this check exists to ensure that customers are not double-charged if we restart the inventorying process. You only get the inventorying order
    # if you move from "no inventorying requested" to "inventorying requested"
    if self.inventorying_status == Box::NO_INVENTORYING_REQUESTED
      generate_inventorying_order(send_admin_email)
    end
    
    self.inventorying_status = Box::INVENTORYING_REQUESTED
  end
  
  def create_shipment
    if self.id.nil?
      raise "Cannot create a shipment on a brand new box"
    end
    
    shipment = Shipment.new
    
    shipment.box_id = self.id
    self.shipments << shipment
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
  
  # def cubic_feet
  #   if self.length.nil? || self.width.nil? || self.height.nil?
  #     return nil
  #   else
  #     divisor = Rails.application.config.box_dimension_divisor
  #     return (self.length/divisor) * (self.width/divisor) * (self.height/divisor)
  #   end
  # end
  
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
  
  def generate_inventorying_order(send_admin_email=false)
    if self.box_type == CUST_BOX_TYPE
      product_id = Rails.application.config.your_box_inventorying_product_id
    elsif self.box_type == VC_BOX_TYPE
      product_id = Rails.application.config.our_box_inventorying_product_id
    else
      raise "Invalid box type for box " << inspect
    end
        
    order = Order.new
    
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
    else
      self.inventorying_order_line_id = order_line.id
    end
    
    if send_admin_email
      AdminMailer.deliver_new_inventorying_order(user, self)
    end
    
    # Note: do not generate charges for the order. This will happen automatically at the end of the month.
  end
  
  def set_box_num
    update_attribute(:box_num, self.user.next_box_num)
  end
  
  def Box.days_in_month(month, year)
    this_month = Date.parse(year.to_s + "-" + month.to_s + "-01")
    ((this_month >> 1) - 1).day
  end
end
