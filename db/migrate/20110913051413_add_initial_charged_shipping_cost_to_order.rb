class AddInitialChargedShippingCostToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :initial_charged_shipping_cost, :float
  end

  def self.down
    remove_column :orders, :initial_charged_shipping_cost
  end
end
