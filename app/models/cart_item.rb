# == Schema Information
# Schema version: 20110627180233
#
# Table name: cart_items
#
#  id         :integer         not null, primary key
#  quantity   :integer
#  cart_id    :integer
#  product_id :integer
#  created_at :datetime
#  updated_at :datetime
#

class CartItem < ActiveRecord::Base
  attr_accessible :product_id, :quantity

  belongs_to :cart

  validates_numericality_of :quantity, :only_integer => true
  validates_presence_of :product_id
end
