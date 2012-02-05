# == Schema Information
# Schema version: 20120204201152
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
  
  def benefit_remaining?
    months_consumed < user_offer_benefit.offer_benefit.num_months
  end
  
  # Returns the percentage of the period between the two dates that actually applies
  def consume_free_storage(start_date, end_date, percent_remaining)
    months_between_total = Date.months_between(start_date, end_date)
    months_remaining = months_between_total * percent_remaining
    if (months_remaining + self.months_consumed) > user_offer_benefit.offer_benefit.num_months
      months_to_consume = user_offer_benefit.offer_benefit.num_months - months_consumed
    else
      months_to_consume = months_remaining
    end
    
    self.months_consumed = (self.months_consumed.nil? ? 0 : self.months_consumed) + months_to_consume

    return Rational(months_to_consume, months_between_total)
  end
end
