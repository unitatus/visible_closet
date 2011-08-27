class RenameBoxDimensionFields < ActiveRecord::Migration
  def self.up
    rename_column :boxes, :height, :box_height
    rename_column :boxes, :width, :box_width
    rename_column :boxes, :length, :box_length
  end

  def self.down
    rename_column :boxes, :box_height, :height
    rename_column :boxes, :box_width, :width
    rename_column :boxes, :box_length, :length
  end
end
