# == Schema Information
# Schema version: 20110720045231
#
# Table name: shipments
#
#  id              :integer         not null, primary key
#  box_id          :integer
#  from_address_id :integer
#  to_address_id   :integer
#  tracking_number :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

class Shipment < ActiveRecord::Base
end
