# == Schema Information
# Schema version: 20111029221959
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
#  discountable  :boolean
#

# Note that a product can be anything the customer could purchase -- including storage services for a box, inventorying services for a box,
# return services for a box, or anything else. Thus, product must behave somewhat polymorphically.
class Product < ActiveRecord::Base
  
  def prepay?
    return false
  end
  
  def vc_box?
    id == Rails.application.config.our_box_product_id || id == Rails.application.config.our_box_product_id_gf
  end
  
  def vc_inventorying?
    id == Rails.application.config.our_box_inventorying_product_id || id == Rails.application.config.our_box_inventorying_product_id_gf
  end
  
  def cust_box?
    id == Rails.application.config.your_box_product_id || id == Rails.application.config.your_box_product_id_gf
  end
  
  def cust_inventorying?
    id == Rails.application.config.your_box_inventorying_product_id || id == Rails.application.config.your_box_inventorying_product_id_gf
  end
  
  def shippable?
    !id.nil? && id != Rails.application.config.item_donation_product_id && id != Rails.application.config.stocking_fee_product_id
  end
  
  def item_service?
    id == Rails.application.config.item_donation_product_id || id == Rails.application.config.item_mailing_product_id
  end
  
  def grandfathered?
    id == Rails.application.config.your_box_product_id_gf \
    || id == Rails.application.config.our_box_product_id_gf \
    || id == Rails.application.config.your_box_inventorying_product_id_gf \
    || id == Rails.application.config.our_box_inventorying_product_id_gf
  end
  
  def box?
    vc_box? || cust_box?
  end
  
  def donation?
    id == Rails.application.config.item_donation_product_id
  end
  
  def item_mailing?
    id == Rails.application.config.item_mailing_product_id
  end
  
  def customer_pays_shipping_up_front?
    return id == Rails.application.config.return_box_product_id
  end
  
  def stocking_fee?
    return id == Rails.application.config.stocking_fee_product_id
  end
  
  def incurs_charge_at_purchase?
    id == Rails.application.config.return_box_product_id || id == Rails.application.config.item_donation_product_id || id == Rails.application.config.item_mailing_product_id || id == Rails.application.config.stocking_fee_product_id
  end
end
