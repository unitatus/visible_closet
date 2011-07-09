class RenameBoxesOrderLine < ActiveRecord::Migration
  def self.up
    rename_column :boxes, :order_line_id, :ordering_order_line_id
  end

  def self.down
    rename_column :boxes, :ordering_order_line_id, :order_line_id
  end
end
