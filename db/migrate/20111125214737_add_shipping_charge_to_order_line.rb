class AddShippingChargeToOrderLine < ActiveRecord::Migration
  def self.up
    add_column :order_lines, :item_mail_shipping_charge_id, :integer, :references => :charges
  end

  def self.down
    remove_column :order_lines, :item_mail_shipping_charge
  end
end
