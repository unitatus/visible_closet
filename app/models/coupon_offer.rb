# == Schema Information
# Schema version: 20120122173933
#
# Table name: offers
#
#  id                 :integer         not null, primary key
#  unique_identifier  :string(255)
#  start_date         :datetime
#  expiration_date    :datetime
#  created_by_user_id :integer
#  type               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  active             :boolean
#

class CouponOffer < Offer
  has_many :coupons, :as => :offer, :dependent => :destroy
  
  def identifier_overridden
    true
  end
  
  def add_coupons(num_coupons)
    for index in 1..num_coupons
      coupon = coupons.new
      if !coupon.save # in case this number doesn't happen to be random
        redo
      end
    end
  end
  
  def coupon_for_user(user)
    coupons.select {|coupon| coupon.user == user }.last
  end
end
