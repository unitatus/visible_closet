class RenameBoxDimensions < ActiveRecord::Migration
  def self.up
    rename_column :boxes, :box_width, :width
    rename_column :boxes, :box_height, :height
    rename_column :boxes, :box_length, :length
  end

  def self.down
  end
end
