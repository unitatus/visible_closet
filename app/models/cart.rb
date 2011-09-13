# == Schema Information
# Schema version: 20110913030008
#
# Table name: carts
#
#  id                   :integer         not null, primary key
#  user_id              :integer
#  created_at           :datetime
#  updated_at           :datetime
#  ordered_at           :datetime
#  status               :string(255)
#  quoted_shipping_cost :float
#

class Cart < ActiveRecord::Base
  has_many :cart_items, :autosave => true, :dependent => :destroy
  has_one :order, :dependent => :destroy
  belongs_to :user

  attr_accessible :id

  def estimated_total
    total_estimate = 0

    cart_items.each do |cart_item|
      total_estimate += cart_item.discount.due_at_signup
    end
 
    total_estimate + self.get_or_quote_shipping
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

  def Cart.new()
    cart = super
    cart.status = "active"
    cart
  end
  
  def empty?
    return cart_items.size == 0
  end
  
  def num_items
    cart_items.size
  end

  # you can't override the build_order method, as ActiveRecord actually adds it to this class, not the parent, so if you override you lose the method!
  # That's polymorphism in rails I guess! :(  
  def build_order_properly(attributes={})
    order = build_order(attributes)
    
    cart_items.each do |cart_item|
      order.order_lines << order.build_order_line( { :product_id => cart_item.product_id, :quantity => cart_item.quantity, :committed_months => cart_item.committed_months } )
    end    
    order
  end  
  
  def remove_cart_item(product_id)
    cart_item = cart_items.select { |c| c.product_id == product_id }[0]
    
    while !cart_item.nil?
      cart_items.delete(cart_item)
      cart_item = cart_items.select { |c| c.product_id == product_id }[0]
    end
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
  
  def num_box_return_requests
    cart_items_with_boxes = cart_items.select { |c| !c.box.nil? }
    puts("cart items with boxes is " + cart_items_with_boxes.inspect)
    cart_items_with_boxes.size
  end
  
  def add_cart_item(product_id, quantity, committed_months)
    cart_item = CartItem.new
    
    cart_item.product_id = product_id
    cart_item.quantity = quantity
    cart_item.committed_months = committed_months
    
    cart_items << cart_item
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
  
  def contains_new_boxes
    new_box_cart_items = cart_items.select { |c| c.product_id == Rails.application.config.your_box_product_id || c.product_id == Rails.application.config.our_box_product_id }
    return !new_box_cart_items.empty?
  end
  
  def contains_ship_charge_items?
    ship_charge_items = cart_items.select { |c| c.product.customer_pays_shipping_up_front? }
    return !ship_charge_items.empty?
  end
  
  def get_or_quote_shipping
    if self.quoted_shipping_cost
      return self.quoted_shipping_cost
    else
      return quote_shipping
    end
  end
  
  def quote_shipping
    if !contains_ship_charge_items?
      return 0.0
    end
    
    grouped_cart_items = group_cart_items_by_address
    fedex = Fedex::Base.new(basic_fedex_options)
    vc_address = Address.find(Rails.application.config.fedex_vc_address_id)
    total_shipping_cost = 0.0
    
    grouped_cart_items.each do |cart_item_group|
      total_shipping_cost += get_shipping_price(fedex, vc_address, cart_item_group[:to_address], cart_item_group[:cart_items])
    end
    
    update_attribute(:quoted_shipping_cost, total_shipping_cost) # this saves the value
    
    return total_shipping_cost
  end
  
  private
  
  def group_cart_items_by_address
    hash_of_arrays = Hash.new
    
    cart_items.each do |cart_item|
      if hash_of_arrays[cart_item.address].nil?
        hash_of_arrays[cart_item.address] = Array.new
      end
      
      hash_of_arrays[cart_item.address] << cart_item
    end
    
    return_array = Array.new
    
    hash_of_arrays.keys.each do |address|
      return_array << { :to_address => address, :cart_items => hash_of_arrays[address] }
    end
    
    return return_array
  end
  
  def get_shipping_price(fedex_connection, from_address, to_address, cart_items)
    shipper = {
      :name => from_address.first_name + " " + from_address.last_name,
      :phone_number => from_address.day_phone
    }
    recipient = {
      :name => to_address.first_name + " " + to_address.last_name,
      :phone_number => to_address.day_phone
    }
    origin = {
       :street_lines => (from_address.address_line_2.blank? ? [from_address.address_line_1] : [from_address.address_line_1, from_address.address_line_2]),
       :city => from_address.city,
       :state => from_address.state,
       :zip => from_address.zip,
       :country => from_address.country
     }
     destination = {
      :street_lines => (to_address.address_line_2.blank? ? [to_address.address_line_1] : [to_address.address_line_1, to_address.address_line_2]),
      :city => to_address.city,
      :state => to_address.state,
      :zip => to_address.zip,
      :country => to_address.country,
      :residential => true # this seems reasonable enough for now; there is a TODO to try to figure this out more precisely
    }
    
    packages = Array.new
    cart_items.each do |cart_item|
      if cart_item.product.customer_pays_shipping_up_front?
        packages << { :weight => cart_item.weight }
      end
    end
    
    fedex_connection.price(
      :shipper => { :contact => shipper, :address => origin },
      :recipient => { :contact => recipient, :address => destination },
      :service_type => Fedex::ServiceTypes::FEDEX_GROUND,
      :packages => packages
    )
  end
  
  def basic_fedex_options
    { 
       :auth_key => Rails.application.config.fedex_auth_key,
       :security_code => Rails.application.config.fedex_security_code,
       :account_number => Rails.application.config.fedex_account_number,
       :meter_number => Rails.application.config.fedex_meter_number, 
       :debug => Rails.application.config.fedex_debug
     }
  end
end
