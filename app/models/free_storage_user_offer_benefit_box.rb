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
  has_many :free_storage_user_offer_benefit_box_credits
  
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
  
  def subtract_days_consumed(days_to_subtract)
    self.days_consumed = self.days_consumed - days_to_subtract
    if self.days_consumed < 0
      self.days_consumed = 0
    end
    
    if self.days_consumed == 0
      self.start_date = nil
    end
  end
  
  def days_consumable
    if start_date.nil?
      nil
    else
      (start_date.to_date + user_offer_benefit.offer_benefit.num_months.months) - start_date.to_date
    end
  end
  
  def days_remaining
    days_consumable - days_consumed
  end
  
  def benefit_remaining?
    start_date.nil? || days_consumable > days_consumed
  end
  
  def consume_day(as_of_day=nil)
    self.days_consumed = self.days_consumed + 1
    if @days_recently_consumed.nil?
      @days_recently_consumed = 1
    else
      @days_recently_consumed += 1
    end
    
    if self.start_date.nil?
      self.start_date = as_of_day
      begin_date = self.start_date.to_date
    else
      if as_of_day <= self.start_date.to_date + 1.months
        begin_date = self.start_date.to_date
      else
        begin_date = Date.new(as_of_day.year, as_of_day.month, start_date.day)
      end
    end
    
    return (begin_date + 1.months) - begin_date
  end
  
  def days_recently_consumed
    if @days_recently_consumed.nil?
      0
    else
      @days_recently_consumed
    end
  end
end
