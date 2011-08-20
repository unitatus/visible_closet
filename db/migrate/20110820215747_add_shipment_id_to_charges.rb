class AddShipmentIdToCharges < ActiveRecord::Migration
  def self.up
    add_column :charges, :shipment_id, :integer, :references => :shipments

    add_index :charges, :shipment_id
  end

  def self.down
    remove_column :charges, :shipment_id
  end
end
