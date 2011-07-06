class AddOrderLineToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :order_line_id, :integer
    add_index :boxes, :order_line_id
  end

  def self.down
    remove_column :boxes, :order_line_id
  end
end
