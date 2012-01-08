class AddChargeableUnitProcessingPropertiesIdToStorageCharge < ActiveRecord::Migration
  def self.up
    add_column :storage_charges, :chargeable_unit_properties_id, :integer, :references => :chargeable_unit_properties
  end

  def self.down
    remove_column :storage_charges, :chargeable_unit_properties_id
  end
end
