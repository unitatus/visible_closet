# == Schema Information
# Schema version: 20110824175202
#
# Table name: addresses
#
#  id                      :integer         not null, primary key
#  first_name              :string(255)
#  last_name               :string(255)
#  day_phone               :string(255)
#  evening_phone           :string(255)
#  address_line_1          :string(255)
#  address_line_2          :string(255)
#  city                    :string(255)
#  state                   :string(255)
#  zip                     :string(255)
#  created_at              :datetime
#  updated_at              :datetime
#  address_name            :string(255)
#  user_id                 :integer
#  country                 :string(255)
#  status                  :string(255)
#  comment                 :string(255)
#  fedex_validation_status :string(255)
#

class ShipmentAddress < Address
  has_one :shipment
  
  # All shipment addresses are created with shipments based on known good addresses.
  # We do not do validation so as to save precious seconds in the shipment create process.
  def external_validation
    return true
  end
end
