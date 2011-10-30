class AddServiceItemIdToOrderLines < ActiveRecord::Migration
  def self.up
    add_column :order_lines, :service_item_id, :integer, :references => :stored_items
  end

  def self.down
    remove_column :order_lines, :service_item_id
  end
end
