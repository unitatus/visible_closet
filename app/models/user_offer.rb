# == Schema Information
# Schema version: 20120129010630
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

class UserOffer < ActiveRecord::Base
  belongs_to :user
  belongs_to :offer
  has_many :user_offer_benefits, :dependent => :destroy

  # Want to show the offer information in its entirety
  def method_missing(meth, *args, &blk)
    meth.to_s == 'id' ? super : offer.send(meth, *args, &blk)
  rescue NoMethodError
    super
  end
  
  def benefit_used_messages
    # have to flatten because each user offer benefit will return an array; without flatten we'll have an array of arrays
    user_offer_benefits.collect {|user_offer_benefit| user_offer_benefit.benefit_used_messages }.flatten
  end
  
  def benefit_remaining_messages
    # have to flatten because each user offer benefit will return an array; without flatten we'll have an array of arrays
    user_offer_benefits.collect {|user_offer_benefit| user_offer_benefit.benefit_remaining_messages }.flatten
  end
  
  def used?
    user_offer_benefits.select {|user_offer_benefit| user_offer_benefit.used? }.any?
  end
end
