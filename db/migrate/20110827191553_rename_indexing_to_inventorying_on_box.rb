class RenameIndexingToInventoryingOnBox < ActiveRecord::Migration
  def self.up
    rename_column :boxes, :indexing_status, :inventorying_status
    rename_column :boxes, :indexing_order_line_id, :inventorying_order_line_id
  end

  def self.down
    rename_column :boxes, :inventorying_status, :indexing_status
    rename_column :boxes, :inventorying_order_line_id, :indexing_order_line_id
  end
end
