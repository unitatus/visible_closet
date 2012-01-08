class RenameDimensionSetToChargeableUnitProperties < ActiveRecord::Migration
  def self.up
    rename_column :dimension_sets, :measured_object_id, :chargeable_unit_id
    rename_column :dimension_sets, :measured_object_type, :chargeable_unit_type
    rename_table :dimension_sets, :chargeable_unit_properties
  end

  def self.down
    rename_table :chargeable_unit_properties, :dimension_sets
    rename_column :dimension_sets, :chargeable_unit_id, :measured_object_id
    rename_column :dimension_sets, :chargeable_unit_type, :measured_object_type
  end
end
