# == Schema Information
# Schema version: 20110923232835
#
# Table name: storage_charges
#
#  box_id          :integer
#  charge_id       :integer
#  subscription_id :integer
#  start_date      :datetime
#  end_date        :datetime
#

class StorageCharge < ActiveRecord::Base
  belongs_to :box
  belongs_to :charge
  belongs_to :subscription
  
  validates_presence_of :box
  validates_presence_of :charge
end
