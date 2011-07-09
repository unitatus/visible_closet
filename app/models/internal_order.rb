# == Schema Information
# Schema version: 20110709182101
#
# Table name: orders
#
#  id                  :integer         not null, primary key
#  cart_id             :integer
#  ip_address          :string(255)
#  user_id             :integer
#  created_at          :datetime
#  updated_at          :datetime
#  billing_address_id  :integer
#  shipping_address_id :integer
#

class InternalOrder < Order
  def validate_card
    return true
  end
end
