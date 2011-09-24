# == Schema Information
# Schema version: 20110924185624
#
# Table name: storage_charges
#
#  id         :integer         not null, primary key
#  box_id     :integer
#  charge_id  :integer
#  start_date :datetime
#  end_date   :datetime
#

class StorageCharge < ActiveRecord::Base
  belongs_to :box
  belongs_to :charge
  
  validates_presence_of :box
  validates_presence_of :charge
end
