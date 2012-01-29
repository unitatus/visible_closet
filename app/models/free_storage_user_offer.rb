# == Schema Information
# Schema version: 20120129012225
#
# Table name: user_offers
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  offer_id   :integer
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class FreeStorageUserOffer < UserOffer

end
