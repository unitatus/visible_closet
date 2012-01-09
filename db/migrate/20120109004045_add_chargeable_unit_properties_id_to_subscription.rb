class AddChargeableUnitPropertiesIdToSubscription < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :chargeable_unit_properties_id, :integer, :references => :chargeable_unit_properties
  end

  def self.down
    remove_column :subscriptions, :chargeable_unit_properties_id
  end
end
