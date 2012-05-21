# == Schema Information
# Schema version: 20120520232229
#
# Table name: user_offers
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  offer_id   :integer
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  coupon_id  :integer
#

class FreeStorageUserOffer < UserOffer

end
