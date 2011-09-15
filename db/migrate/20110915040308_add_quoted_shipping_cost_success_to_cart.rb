class AddQuotedShippingCostSuccessToCart < ActiveRecord::Migration
  def self.up
    add_column :carts, :quoted_shipping_cost_success, :boolean
  end

  def self.down
    remove_column :carts, :quoted_shipping_cost_success
  end
end
