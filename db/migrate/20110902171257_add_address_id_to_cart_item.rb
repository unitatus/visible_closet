class AddAddressIdToCartItem < ActiveRecord::Migration
  def self.up
    add_column :cart_items, :address_id, :integer, :references => :addresses
  end

  def self.down
    remove_column :cart_items, :address_id
  end
end
