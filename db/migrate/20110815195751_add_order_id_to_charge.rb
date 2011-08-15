class AddOrderIdToCharge < ActiveRecord::Migration
  def self.up
    add_column :charges, :order_id, :integer, :references => :orders
  end

  def self.down
    remove_column :charges, :order_id
  end
end
