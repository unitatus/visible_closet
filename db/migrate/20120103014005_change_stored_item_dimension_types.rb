class ChangeStoredItemDimensionTypes < ActiveRecord::Migration
  def self.up
    change_column :stored_items, :height, :float
    change_column :stored_items, :width, :float
    change_column :stored_items, :length, :float
  end

  def self.down
    change_column :stored_items, :height, :integer
    change_column :stored_items, :width, :integer
    change_column :stored_items, :length, :integer
  end
end
