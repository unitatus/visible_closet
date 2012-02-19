# == Schema Information
# Schema version: 20120219180254
#
# Table name: credits
#
#  id                                  :integer         not null, primary key
#  amount                              :float
#  user_id                             :integer
#  created_at                          :datetime
#  updated_at                          :datetime
#  description                         :string(255)
#  created_by_admin_id                 :integer
#  storage_charge_processing_record_id :integer
#

class Credit < ActiveRecord::Base
  has_one :payment_transaction
  belongs_to :user
  belongs_to :created_by_admin, :class_name => "User"
  belongs_to :storage_charge_processing_record # if generated from an offer as part of monthly processing
  has_many :free_storage_user_offer_benefit_box_credits, :dependent => :destroy
  
  def deletable?
    payment_transaction.nil?
  end
  
  def associate_with(free_storage_user_offer_benefit_box, num_days_consumed)
    benefit_credit = free_storage_user_offer_benefit_box_credits.build(:days_consumed => num_days_consumed)
    benefit_credit.free_storage_user_offer_benefit_box = free_storage_user_offer_benefit_box
    return benefit_credit
  end
end
