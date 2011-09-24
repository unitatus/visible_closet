class AddMissingIndexes < ActiveRecord::Migration
  def self.up
    add_index :addresses, :user_id
    add_index :charges, :user_id
    add_index :boxes, :inventorying_order_line_id
    add_index :stored_item_tags, :stored_item_id
    add_index :invoices, :order_id
    add_index :subscriptions, :user_id
    add_index :boxes, :subscription_id
    add_index :charges, :order_id
    add_index :storage_charges, :box_id
    add_index :storage_charges, :subscription_id
    add_index :storage_charges, :charge_id
  end

  def self.down
    remove_index :addresses, :user_id
    remove_index :charges, :user_id
    remove_index :boxes, :inventorying_order_line_id
    remove_index :stored_item_tags, :stored_item_id
    remove_index :invoices, :order_id
    remove_index :subscriptions, :user_id
    remove_index :boxes, :subscription_id
    remove_index :charges, :order_id
    remove_index :charges, :shipment_id
    remove_index :storage_charge, :box_id
    remove_index :storage_charge, :subscription_id
    remove_index :storage_charge, :charge_id
  end
end
