class AddChargeRequestedToShipment < ActiveRecord::Migration
  def self.up
    add_column :shipments, :charge_requested, :boolean
  end

  def self.down
    remove_column :shipments, :charge_requested
  end
end
