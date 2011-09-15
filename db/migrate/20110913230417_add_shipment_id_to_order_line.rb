class AddShipmentIdToOrderLine < ActiveRecord::Migration
  def self.up
    add_column :order_lines, :shipment_id, :integer, :references => :shipments
  end

  def self.down
    remove_column :order_lines, :shipment_id
  end
end
