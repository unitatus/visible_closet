class AddShipmentIdToStoredItem < ActiveRecord::Migration
  def self.up
    add_column :stored_items, :shipment_id, :integer, :references => :shipments
  end

  def self.down
    remove_column :stored_items, :shipment_id
  end
end
