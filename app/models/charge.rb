# == Schema Information
# Schema version: 20110913041338
#
# Table name: charges
#
#  id             :integer         not null, primary key
#  user_id        :integer
#  total_in_cents :integer
#  product_id     :integer
#  created_at     :datetime
#  updated_at     :datetime
#  order_id       :integer
#  shipment_id    :integer
#  comments       :string(255)
#

# Conceptually, a charge can be related to: a product ordered; a box in storage (storage charge); a shipment (shipping charge); or an order (total shipping cost).
class Charge < ActiveRecord::Base
  belongs_to :order
  belongs_to :shipment
  belongs_to :product
end
