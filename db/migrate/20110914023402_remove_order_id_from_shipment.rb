class RemoveOrderIdFromShipment < ActiveRecord::Migration
  def self.up
    remove_column :shipments, :order_id
  end

  def self.down
    add_column :shipments, :order_id, :integer, :references => :orders
  end
end
