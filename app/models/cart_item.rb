# == Schema Information
# Schema version: 20110902171257
#
# Table name: cart_items
#
#  id               :integer         not null, primary key
#  quantity         :integer
#  cart_id          :integer
#  product_id       :integer
#  created_at       :datetime
#  updated_at       :datetime
#  committed_months :integer
#  box_id           :integer
#  address_id       :integer
#

class CartItem < ActiveRecord::Base
  belongs_to :product
  belongs_to :cart
  belongs_to :box
  belongs_to :address, :dependent => :destroy, :autosave => true

  validates_numericality_of :quantity, :only_integer => true, :greater_than_or_equal_to => 0, :message => "Please enter only positive integers."
  
  validates_presence_of :product_id
  
  def get_or_pull_address
    if self.address.nil?
      update_attribute(:address_id, cart.user.default_shipping_address_id)
      self.address = cart.user.default_shipping_address
    end 
    
    return self.address
  end
  
  def discount?
    return self.discount.unit_discount_perc > 0.0
  end
  
  def discount
    Discount.new(product, quantity, committed_months)
  end
  
  def description
    if self.box.nil?
      product.name
    else
      product.name + " for box " + box.box_num.to_s
    end
  end
  
  def weight
    if box
      box.weight * self.quantity
    else
      raise "Weight not known."
    end
  end
end
