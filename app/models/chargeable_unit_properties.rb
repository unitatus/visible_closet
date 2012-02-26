# == Schema Information
# Schema version: 20120226214729
#
# Table name: chargeable_unit_properties
#
#  id                   :integer         not null, primary key
#  height               :float
#  width                :float
#  length               :float
#  location             :string(255)
#  chargeable_unit_id   :integer
#  chargeable_unit_type :string(255)
#  description          :string(255)
#  charging_start_date  :datetime
#  charging_end_date    :datetime
#

class ChargeableUnitProperties < ActiveRecord::Base
  belongs_to :chargeable_unit, :polymorphic => true
  has_many :storage_charges, :order => "end_date ASC" # This way .first means the first ever charge, and .last means the last ever storage charge, by end_date
  has_many :subscriptions
  
  def current_subscription
    subscription_on(Date.today)
  end
  
  def subscription_on(date)
    subscriptions.select { |subscription| subscription.applies_on(date) }.last
  end
  
  # the idea behind this is to return the day before when we should start charging
  def latest_charge_end_date
    if storage_charges.size == 0 || storage_charges.last.end_date.nil?
      return charging_start_date ? charging_start_date.to_date - 1 : nil
    else
      return storage_charges.last.end_date.to_date
    end
  end
  
  def in_storage_on(a_date)
    if self.charging_start_date.nil?
      return false
    else
      return self.charging_start_date.to_date <= a_date && (self.charging_end_date.nil? || self.charging_end_date.to_date >= a_date)
    end
  end
  
  def chargable?
    if self.charging_start_date.nil?
      return false
    else
      return self.charging_end_date.nil? \
        || self.storage_charges.size == 0 \
        || self.storage_charges.last.end_date.nil? \
        || self.charging_end_date > self.storage_charges.last.end_date
    end
  end
  
  def in_storage_on(a_date)
    if self.charging_start_date.nil?
      return false
    else
      return self.charging_start_date.to_date <= a_date && (self.charging_end_date.nil? || self.charging_end_date.to_date >= a_date)
    end
  end
  
  def charged_already_on(day)
    # Hash is for performance
    @days_already_charged ||= Hash.new
    
    if @days_already_charged[day]
      return true
    elsif !@days_already_charged[day].nil?
      return false
    end
    
    storage_charges.each do |storage_charge|
      if storage_charge.start_date && storage_charge.start_date <= day && storage_charge.end_date >= day
        @days_already_charged[day] = true and return true
      end
    end
    
    @days_already_charged[day] = false and return false
  end
  
  def has_charges?
    self.storage_charges.size > 0
  end
end
