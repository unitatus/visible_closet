# == Schema Information
# Schema version: 20120129020438
#
# Table name: free_storage_user_offer_benefit_boxes
#
#  id                    :integer         not null, primary key
#  user_offer_benefit_id :integer
#  box_id                :integer
#  months_consumed       :float
#  created_at            :datetime
#  updated_at            :datetime
#

class FreeStorageUserOfferBenefitBox < ActiveRecord::Base
  belongs_to :box
  belongs_to :user_offer_benefit
  
  def used?
    months_consumed > 0
  end
  
  def months_consumed
    if read_attribute(:months_consumed).nil?
      0
    else
      read_attribute(:months_consumed)
    end
  end
end
