# == Schema Information
# Schema version: 20120129012225
#
# Table name: user_offer_benefits
#
#  id               :integer         not null, primary key
#  user_offer_id    :integer
#  offer_benefit_id :integer
#  type             :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

class UserOfferBenefit < ActiveRecord::Base
  belongs_to :user_offer
  belongs_to :offer_benefit
  
  def benefit_used_messages
    raise "This method must be overridden."
  end
  
  def benefit_remaining_messages
    raise "This method must be overridden."
  end
end
