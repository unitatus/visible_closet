# == Schema Information
# Schema version: 20120218213729
#
# Table name: free_storage_user_offer_benefit_boxes
#
#  id                    :integer         not null, primary key
#  user_offer_benefit_id :integer
#  box_id                :integer
#  created_at            :datetime
#  updated_at            :datetime
#  days_consumed         :integer
#  start_date            :datetime
#

class FreeStorageUserOfferBenefitBox < ActiveRecord::Base
  belongs_to :box
  belongs_to :user_offer_benefit
  
  def used?
    days_consumed > 0
  end
  
  def started?
    !start_date.nil?
  end
  
  def days_consumed
    if read_attribute(:days_consumed).nil?
      0
    else
      read_attribute(:days_consumed)
    end
  end
  
  def percent_consumed
    if start_date.nil?
      0
    else
      Rational(days_consumed, days_consumable)
    end
  end
  
  def days_consumable
    if start_date.nil?
      nil
    else
      (start_date + user_offer_benefit.offer_benefit.num_months.months) - start_date
    end
  end
  
  def days_remaining
    days_consumable - days_consumed
  end
  
  def benefit_remaining?
    start_date.nil? || days_consumable > days_consumed
  end
  
  # Returns the percentage of the period between the two dates that actually applies
  # def consume_free_storage(start_date, end_date, percent_remaining)
  #   months_between_total = Date.months_between(start_date, end_date)
  #   months_remaining = months_between_total * percent_remaining
  #   if (months_remaining + self.months_consumed) > user_offer_benefit.offer_benefit.num_months
  #     months_to_consume = user_offer_benefit.offer_benefit.num_months - months_consumed
  #   else
  #     months_to_consume = months_remaining
  #   end
  #   
  #   self.months_consumed = (self.months_consumed.nil? ? 0 : self.months_consumed) + months_to_consume
  # 
  #   return Rational(months_to_consume, months_between_total)
  # end
  
  def consume_day(date_if_nil=nil)
    self.days_consumed = self.days_consumed + 1
    if self.start_date.nil?
      self.start_date = date_if_nil
    end
  end
end
