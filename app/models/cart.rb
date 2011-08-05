# == Schema Information
# Schema version: 20110701051132
#
# Table name: carts
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#  ordered_at :datetime
#  status     :string(255)
#

class Cart < ActiveRecord::Base
  has_many :cart_items, :autosave => true
  has_one :order

  attr_accessible :id

  def estimated_total
    total_estimate = 0

    cart_items.each do |cart_item|
      product = Product.find(cart_item.product_id)

      total_estimate += (cart_item.quantity * product.due_at_signup)
    end
 
    total_estimate
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
  
  def num_items
    cart_items.size
  end

  # you can't override the build_order method, as ActiveRecord actually adds it to this class, not the parent, so if you override you lose the method!
  # That's polymorphism in rails I guess! :(  
  def build_order_properly(attributes={})
    order = build_order(attributes)
    
    cart_items.each do |cart_item|
      order.order_lines << order.build_order_line( { :product_id => cart_item.product_id, :quantity => cart_item.quantity } )
    end    
    order
  end  
end
