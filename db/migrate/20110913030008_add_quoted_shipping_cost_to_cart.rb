class AddQuotedShippingCostToCart < ActiveRecord::Migration
  def self.up
    add_column :carts, :quoted_shipping_cost, :float
  end

  def self.down
    remove_column :carts, :quoted_shipping_cost
  end
end
