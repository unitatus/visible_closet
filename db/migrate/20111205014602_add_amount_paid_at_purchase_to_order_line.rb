class AddAmountPaidAtPurchaseToOrderLine < ActiveRecord::Migration
  def self.up
    add_column :order_lines, :amount_paid_at_purchase, :float
  end

  def self.down
    remove_column :order_lines, :amount_paid_at_purchase
  end
end
