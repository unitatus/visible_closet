# == Schema Information
# Schema version: 20110915040308
#
# Table name: carts
#
#  id                           :integer         not null, primary key
#  user_id                      :integer
#  created_at                   :datetime
#  updated_at                   :datetime
#  ordered_at                   :datetime
#  status                       :string(255)
#  quoted_shipping_cost         :float
#  quoted_shipping_cost_success :boolean
#

class Cart < ActiveRecord::Base
  has_many :cart_items, :autosave => true, :dependent => :destroy
  has_one :order, :dependent => :destroy
  belongs_to :user

  attr_accessible :id, :quoted_shipping_cost, :quoted_shipping_cost_success

  def Cart.new()
    cart = super
    cart.status = "active"
    cart
  end

  def estimated_total
    total_estimate = 0

    cart_items.each do |cart_item|
      total_estimate += cart_item.discount.charged_at_purchase + cart_item.discount.prepaid_at_purchase
    end
 
    if contains_ship_charge_items? && quoted_shipping_cost_success
      total_estimate + quoted_shipping_cost
    else
      total_estimate
    end
  end

  def get_quantity(product_id)
    found_cart_items = cart_items.select { |c| c.product_id == product_id }

    total_qty = 0

    found_cart_items.each do |c|
      total_qty += c.quantity
    end

    total_qty
  end

  def mark_ordered
    self.status = "ordered"
    self.ordered_at = Time.now
  end

  def Cart.find_by_user_id(user_id)
    raise "Do not use this method. You must specify find_active_by_user_id or find_by_user_id_and_status, or implement a new method"
  end

  def Cart.find_active_by_user_id(user_id)
    Cart.find_by_user_id_and_status(user_id, "active")
  end
  
  def empty?
    return cart_items.size == 0
  end
  
  def num_items
    cart_items.size
  end

  def build_order_with_extension(attributes={})
    order = build_order_without_extension(attributes)
    order.cart = self
    order.user = self.user
    
    cart_items.each do |cart_item|
      order.order_lines << order.build_order_line( { :product_id => cart_item.product_id, :quantity => cart_item.quantity, \
        :committed_months => cart_item.committed_months, :shipping_address_id => cart_item.address_id, :service_box_id => cart_item.box_id, \
        :service_item_id => cart_item.stored_item_id } )
    end    
    order
  end
  
  alias_method_chain :build_order, :extension
  
  def remove_cart_item(product_id)
    cart_item = cart_items.select { |c| c.product_id == product_id }[0]
    
    while !cart_item.nil?
      cart_items.delete(cart_item)
      cart_item = cart_items.select { |c| c.product_id == product_id }[0]
    end
  end
  
  def free_shipping?
    cart_items.each do |cart_item|
      if !cart_item.discount.free_shipping?
        return false
      end
    end
    
    return true
  end
  
  def remove_return_box(box)
    cart_items_to_remove = cart_items.select { |c| c.box == box }
    
    cart_items_to_remove.each do |cart_item|
      cart_items.delete(cart_item)
    end
  end
  
  def contains_return_request_for(box)
    found_items = cart_items.select { |c| c.box == box }
    
    return !found_items.empty?
  end
  
  def contains_service_request_for(stored_item)
    found_items = cart_items.select { |c| c.stored_item == stored_item }
    
    return !found_items.empty?
  end
  
  def contains_donation_request_for(stored_item)
    found_items = cart_items.select { |c| c.stored_item == stored_item && c.product.donation? }
    
    return !found_items.empty?
  end
  
  def contains_mailing_request_for(stored_item)
    found_items = cart_items.select { |c| c.stored_item == stored_item && c.product.item_mailing? }
    
    return !found_items.empty?
  end
  
  def num_box_return_requests
    cart_items_with_boxes = cart_items.select { |c| !c.box.nil? }
    cart_items_with_boxes.size
  end
  
  def num_item_service_requests
    cart_items_with_item_service_requests = cart_items.select { |c| !c.stored_item.nil? }
    cart_items_with_item_service_requests.size
  end
  
  def add_cart_item(product_id, quantity, committed_months)
    cart_item = CartItem.new
    
    cart_item.product_id = product_id
    cart_item.quantity = quantity
    cart_item.committed_months = committed_months
    
    cart_items << cart_item
    
    if cart_item.product.box?
      setup_item = CartItem.new
      setup_item.product_id = Rails.application.config.stocking_fee_product_id
      setup_item.quantity = quantity
      setup_item.committed_months = committed_months
      
      cart_items << setup_item
    end
  end
  
  def stocking_fee_line
    cart_items.select {|cart_item| cart_item.product.stocking_fee? }.first
  end
  
  def add_return_request_for(obj)
    if obj.is_a?(Box)
      cart_item = CartItem.new
      
      cart_item.product_id = Rails.application.config.return_box_product_id
      cart_item.quantity = 1
      cart_item.box = obj
      
      cart_items << cart_item
    else
      raise "Invalid cart item object."
    end
  end
  
  def add_donation_request_for(obj)
    if obj.is_a?(StoredItem)
      cart_item = CartItem.new
      
      cart_item.product_id = Rails.application.config.item_donation_product_id
      cart_item.quantity = 1
      cart_item.stored_item = obj
      
      cart_items << cart_item
    else
      raise "Invalid cart item object"
    end
  end
  
  def remove_service_request_for(stored_item)
    cart_items_to_remove = cart_items.select { |c| c.stored_item == stored_item }
    
    cart_items_to_remove.each do |cart_item|
      cart_items.delete(cart_item)
    end
  end
  
  def add_mailing_request_for(stored_item)
    cart_item = CartItem.new
    
    cart_item.product_id = Rails.application.config.item_mailing_product_id
    cart_item.quantity = 1
    cart_item.stored_item = stored_item
    
    cart_items << cart_item
  end
  
  def contains_new_boxes
    new_box_cart_items = cart_items.select { |c| c.product_id == Rails.application.config.your_box_product_id || c.product_id == Rails.application.config.our_box_product_id }
    return !new_box_cart_items.empty?
  end
  
  def contains_new_cust_boxes
    new_cust_boxes = cart_items.select { |c| c.product_id == Rails.application.config.your_box_product_id }
    return !new_cust_boxes.empty?
  end
  
  def contains_ship_charge_items?
    ship_charge_items = cart_items.select { |c| c.product.customer_pays_shipping_up_front? }
    return !ship_charge_items.empty?
  end
  
  def contains_item_mailings?
    item_mailing_items = cart_items.select { |c| c.product.item_mailing? }
    return !item_mailing_items.empty?
  end
  
  def contains_only_ordered_boxes
    the_ordered_box_lines = self.ordered_box_lines
    
    return the_ordered_box_lines.size > 0 && the_ordered_box_lines.size == self.cart_items.size
  end
  
  def contains_ordered_boxes
    ordered_box_lines.size > 0 
  end
  
  def ordered_box_lines
    cart_items.select { |cart_item| cart_item.product.id == Rails.application.config.your_box_product_id \
      || cart_item.product.id == Rails.application.config.our_box_product_id }
  end
  
  def quote_shipping
    if !contains_ship_charge_items?
      update_attributes(:quoted_shipping_cost => 0.0, :quoted_shipping_cost_success => false) and return 0.0
    end

    total_shipping_cost = 0.0
    
    begin
      Shipment.get_shipping_prices(create_address_package_mappings).each do |pricing_line|
        total_shipping_cost += pricing_line[:shipping_price]
      end
      update_attribute(:quoted_shipping_cost_success, true)
    rescue Fedex::FedexError => e
      update_attributes(:quoted_shipping_cost_success => false, :quoted_shipping_cost => nil) and return
    end
    
    total_shipping_cost = total_shipping_cost * (1 + Rails.application.config.shipping_up_percent)
    
    update_attribute(:quoted_shipping_cost, total_shipping_cost) # this saves the value
    
    return total_shipping_cost
  end
  
  def vc_box_line
    cart_items.each do |cart_item|
      if cart_item.vc_box?
        return cart_item
      end
    end
    
    return nil
  end
  
  def cust_box_line
    cart_items.each do |cart_item|
      if cart_item.cust_box?
        return cart_item
      end
    end
    
    return nil
  end
  
  private
  
  def create_address_package_mappings
    hash_of_arrays = Hash.new
    from_address = Address.find(Rails.application.config.fedex_vc_address_id)
    
    cart_items.each do |cart_item|
      if cart_item.customer_pays_shipping_up_front?
        if hash_of_arrays[cart_item.get_or_pull_address].nil?
          hash_of_arrays[cart_item.address] = Array.new
        end
      
        hash_of_arrays[cart_item.address] << { :weight => cart_item.weight, :length => cart_item.length, :width => cart_item.width, :height => cart_item.height }
      end
    end
    
    return_array = Array.new
    
    hash_of_arrays.keys.each do |address|
      return_array << { :to_address => address, :from_address => from_address, :packages => hash_of_arrays[address] }
    end
    
    return return_array
  end  
end
