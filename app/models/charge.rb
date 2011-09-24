# == Schema Information
# Schema version: 20110923230002
#
# Table name: charges
#
#  id                     :integer         not null, primary key
#  user_id                :integer
#  total_in_cents         :integer
#  product_id             :integer
#  created_at             :datetime
#  updated_at             :datetime
#  order_id               :integer
#  shipment_id            :integer
#  comments               :string(255)
#  payment_transaction_id :integer
#  box_id                 :integer
#

# Conceptually, a charge can be related to: a product ordered (order_id and product_id set); a box in storage (box_id set); 
# a shipment (shipping_id set); or an order's shipping costs (only order id set). The reason for this is workflow. You pay for shipping once per order,
# not once for each line, even though shipments (in this case, of returns) get processed potentially individually, so in that case the order id for
# the charge is set, not the shipping id. Shipping charges that are explicitly charged for an individual shipment occur when a user does not commit
# enough for free shipping, but we don't know the shipping cost yet because we haven't actually shipped it (and can't charge them beforehand because
# we don't know the package weight) so we can't charge them for the order's shipping cost, then later when the shipment is processed we record that
# in the system, at which point the shipment gets "charge" and that charge has a shipment id.

# In retrospect, this is a bit confusing -- potential to refactor so that charges can be associated with order lines instead of orders, to tie them
# better with actual shipments made later. -DZ 20110922
class Charge < ActiveRecord::Base
  belongs_to :order
  belongs_to :shipment
  belongs_to :product
  # Basic assumption: a charge must be paid in full, so if it has a payment that means it is paid. Thus, a charge can have only one payment, though a payment can have more than one charge.
  belongs_to :payment_transaction
  has_one :storage_charge
  
  def Charge.amalgamate(charges)
    sum_total = 0.0
    
    charges.each do |charge|
      sum_total += charge.total_in_cents / 100
    end
    
    sum_total
  end
end
