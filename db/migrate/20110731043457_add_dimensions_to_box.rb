class AddDimensionsToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :height, :float
    add_column :boxes, :width, :float
    add_column :boxes, :length, :float
    add_column :boxes, :weight, :float
  end

  def self.down
    remove_column :boxes, :weight
    remove_column :boxes, :length
    remove_column :boxes, :width
    remove_column :boxes, :height
  end
end
