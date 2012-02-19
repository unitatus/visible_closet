# == Schema Information
# Schema version: 20120219180254
#
# Table name: free_storage_user_offer_benefit_box_credits
#
#  id                                     :integer         not null, primary key
#  free_storage_user_offer_benefit_box_id :integer
#  credit_id                              :integer
#  days_consumed                          :integer
#  created_at                             :datetime
#  updated_at                             :datetime
#

class FreeStorageUserOfferBenefitBoxCredit < ActiveRecord::Base
  belongs_to :credit
  belongs_to :free_storage_user_offer_benefit_box
  before_destroy :undo_offer_benefits
  
  def undo_offer_benefits
    free_storage_user_offer_benefit_box.subtract_days_consumed(days_consumed)
    free_storage_user_offer_benefit_box.save
  end
end
