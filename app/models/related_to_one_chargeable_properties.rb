# For more on this pattern, visit http://mediumexposure.com/multiple-table-inheritance-active-record/
module RelatedToOneChargeableProperties
  def self.included(base)
    base.belongs_to :chargeable_unit_properties
  end
  
  # No such thing as "belongs to through"
  def chargeable_unit
    self.chargeable_unit_properties.nil? ? nil : self.chargeable_unit_properties.chargeable_unit
  end
  
  # No such thing as "belongs to through"
  def chargeable_unit=(chargeable_unit)
    if chargeable_unit.nil?
      self.chargeable_unit_properties = nil
    else
      self.chargeable_unit_properties = chargeable_unit.chargeable_unit_properties
    end
  end
end