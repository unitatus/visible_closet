# == Schema Information
# Schema version: 20110805043232
#
# Table name: products
#
#  id            :integer         not null, primary key
#  name          :string(255)
#  price         :float
#  created_at    :datetime
#  updated_at    :datetime
#  price_comment :string(255)
#  first_due     :string(255)
#

class Product < ActiveRecord::Base
  AT_SIGNUP = "at_signup"
  AT_RECEIPT = "at_receipt"
  
  attr_accessible :id, :name, :price, :price_comment, :created_at, :updated_at
  
  def due_at_signup
    if first_due == AT_SIGNUP
      self.price
    else
      0.0
    end
  end
  
  def vc_box?
    id == Rails.application.config.our_box_product_id
  end
  
  def cust_box?
    id == Rails.application.config.your_box_product_id
  end
  
  def box?
    vc_box? || cust_box?
  end
  
  def customer_pays_shipping_up_front?
    return id == Rails.application.config.return_box_product_id = 5
  end
end
