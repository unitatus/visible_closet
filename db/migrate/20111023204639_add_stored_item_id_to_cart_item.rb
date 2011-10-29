class AddStoredItemIdToCartItem < ActiveRecord::Migration
  def self.up
    add_column :cart_items, :stored_item_id, :integer, :references => :stored_items
  end

  def self.down
    remove_column :cart_items, :stored_item_id
  end
end
