# == Schema Information
# Schema version: 20110729155026
#
# Table name: orders
#
#  id                  :integer         not null, primary key
#  cart_id             :integer
#  ip_address          :string(255)
#  user_id             :integer
#  created_at          :datetime
#  updated_at          :datetime
#  shipping_address_id :integer
#

class InternalOrder < Order
  def validate_card
    return true
  end
end
