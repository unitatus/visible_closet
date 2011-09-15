class AddBoxIdToCartItem < ActiveRecord::Migration
  def self.up
    add_column :cart_items, :box_id, :integer, :references => :boxes
  end

  def self.down
    remove_column :cart_items, :box_id
  end
end
