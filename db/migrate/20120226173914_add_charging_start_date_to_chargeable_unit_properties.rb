class AddChargingStartDateToChargeableUnitProperties < ActiveRecord::Migration
  def self.up
    add_column :chargeable_unit_properties, :charging_start_date, :datetime
  end

  def self.down
    remove_column :chargeable_unit_properties, :charging_start_date
  end
end
