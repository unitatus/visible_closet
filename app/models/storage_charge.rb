# == Schema Information
# Schema version: 20120108233808
#
# Table name: storage_charges
#
#  id                                  :integer         not null, primary key
#  charge_id                           :integer
#  start_date                          :datetime
#  end_date                            :datetime
#  storage_charge_processing_record_id :integer
#  chargeable_unit_properties_id       :integer
#

class StorageCharge < ActiveRecord::Base
  include RelatedToOneChargeableProperties
  
  belongs_to :charge
  belongs_to :storage_charge_processing_record
  
  validates_presence_of :chargeable_unit
  validates_presence_of :charge
  
  # SQLite and some other databases can't tell the difference between a datetime and a date, but in the case of a storage charge, there is no such thing as time. We must
  # therefore overwrite things
  def start_date
    read_attribute(:start_date).nil? ? nil : read_attribute(:start_date).to_date
  end
  
  def end_date
    read_attribute(:end_date).nil? ? nil : read_attribute(:end_date).to_date
  end
end
