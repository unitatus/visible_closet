class AddDimensionsToStoredItem < ActiveRecord::Migration
  def self.up
    add_column :stored_items, :height, :integer
    add_column :stored_items, :width, :integer
    add_column :stored_items, :length, :integer
    add_column :stored_items, :location, :string
    add_column :stored_items, :creator_id, :integer, :references => :users
  end

  def self.down
    remove_column :stored_items, :creator_id
    remove_column :stored_items, :location
    remove_column :stored_items, :length
    remove_column :stored_items, :width
    remove_column :stored_items, :height
  end
end
