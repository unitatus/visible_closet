class ShipmentAddress < Address
  has_one :shipment
  
  # All shipment addresses are created with shipments based on known good addresses.
  # We do not do validation so as to save precious seconds in the shipment create process.
  def external_validation
    return true
  end
end