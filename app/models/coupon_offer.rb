# == Schema Information
# Schema version: 20120122055753
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
#

class CouponOffer < Offer
  has_many :coupons, :dependent => :destroy
  
  def identifier_overridden
    true
  end
end
