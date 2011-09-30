class AddInventoriedAtToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :inventoried_at, :datetime
  end

  def self.down
    remove_column :boxes, :inventoried_at
  end
end
