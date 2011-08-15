# == Schema Information
# Schema version: 20110815001822
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
#

class CartItem < ActiveRecord::Base
  attr_accessible :product_id, :quantity
  belongs_to :product

  belongs_to :cart

  validates_numericality_of :quantity, :only_integer => true, :greater_than_or_equal_to => 0, :message => "Please enter only positive integers."
  
  validates_presence_of :product_id
  
  def discount?
    return self.discount.unit_discount_perc > 0.0
  end
  
  def discount
    Discount.new(product, quantity, committed_months)
  end
end
