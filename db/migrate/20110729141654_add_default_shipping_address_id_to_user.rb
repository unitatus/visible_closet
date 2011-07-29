class AddDefaultShippingAddressIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :default_shipping_address_id, :integer, :references => :addresses
  end

  def self.down
    remove_column :users, :default_shipping_address_id
  end
end
