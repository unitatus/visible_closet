class AddAddressIdToOrderLine < ActiveRecord::Migration
  def self.up
    add_column :order_lines, :shipping_address_id, :integer, :references => :addresses
  end

  def self.down
    remove_column :order_lines, :shipping_address_id
  end
end
