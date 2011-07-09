class AddIndexingOrderLineIdToBoxes < ActiveRecord::Migration
  def self.up
    add_column :boxes, :indexing_order_line_id, :integer, :references => :order_lines
  end

  def self.down
    remove_column :boxes, :indexing_order_line_id
  end
end
