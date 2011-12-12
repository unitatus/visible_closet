# == Schema Information
# Schema version: 20111212133514
#
# Table name: charges
#
#  id                  :integer         not null, primary key
#  user_id             :integer
#  total_in_cents      :float
#  product_id          :integer
#  created_at          :datetime
#  updated_at          :datetime
#  order_id            :integer
#  shipment_id         :integer
#  comments            :string(255)
#  created_by_admin_id :integer
#

# Conceptually, a charge can be related to: a product ordered (order_id and product_id set); a box in storage (associated with a storage_charge); 
# a shipment (shipping_id set); an order's shipping costs (only order id set); or nothing at all (in which case created_by_admin_id should be set). 
# The reason for this is workflow. You pay for shipping once per order,
# not once for each line, even though shipments (in this case, of returns) get processed potentially individually, so in that case the order id for
# the charge is set, not the shipping id. Shipping charges that are explicitly charged for an individual shipment occur when a user does not commit
# enough for free shipping, but we don't know the shipping cost yet because we haven't actually shipped it (and can't charge them beforehand because
# we don't know the package weight) so we can't charge them for the order's shipping cost, then later when the shipment is processed we record that
# in the system, at which point the shipment gets "charged" and that charge has a shipment id.

# Also, note that charges are not associated with payments at this time. The user's balance is the sum of all charges and payments. This addresses the
# fact that payments may be made well after charges, and may be for multiple charges, and charges may span payments. Not worth tracking.

# In retrospect, this is a bit confusing -- potential to refactor so that charges can be associated with order lines instead of orders, to tie them
# better with actual shipments made later. -DZ 20110922
class Charge < ActiveRecord::Base
  belongs_to :order
  belongs_to :shipment
  belongs_to :product
  belongs_to :user
  belongs_to :created_by_admin, :class_name => "User"
  # Basic assumption: a charge must be paid in full, so if it has a payment that means it is paid. Thus, a charge can have only one payment, though a payment can have more than one charge.
  belongs_to :payment_transaction
  has_one :storage_charge, :dependent => :destroy
  
  def Charge.amalgamate(charges)
    sum_total = 0.0
    
    charges.each do |charge|
      sum_total += charge.total_in_cents
    end
    
    sum_total.to_f/100.0
  end
  
  def box
    if storage_charge.nil?
      nil
    else
      storage_charge.box
    end
  end
  
  def after_save
    if storage_charge
      storage_charge.save
    end
  end
  
  def associate_with(box, start_date=nil, end_date=nil)
    if !associated_with?(box)
      new_storage_charge = box.storage_charges.build(:start_date => start_date, :end_date => end_date)
      new_storage_charge.charge = self
      self.storage_charge = new_storage_charge
      return new_storage_charge
    end
  end
  
  def associated_with?(box)
    storage_charge && storage_charge.box == box
  end

  def amount
    total_in_cents/100.0
  end
  
  def deletable?
    !created_by_admin_id.nil?
  end
end
