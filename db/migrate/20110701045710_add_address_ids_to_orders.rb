class AddAddressIdsToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :billing_address_id, :integer, :references => :addresses
    add_column :orders, :shipping_address_id, :integer, :references => :addresses
  end

  def self.down
    remove_column :orders, :billing_address_id
    remove_column :orders, :shipping_address_id
  end
end
