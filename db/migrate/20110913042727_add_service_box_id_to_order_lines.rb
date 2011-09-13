class AddServiceBoxIdToOrderLines < ActiveRecord::Migration
  def self.up
    add_column :order_lines, :service_box_id, :integer, :references => :boxes
  end

  def self.down
    remove_column :order_lines, :service_box_id
  end
end
