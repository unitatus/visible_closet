class AddOrderIdToShipment < ActiveRecord::Migration
  def self.up
    add_column :shipments, :order_id, :integer, :references => :orders
  end

  def self.down
    remove_column :shipments, :order_id
  end
end
