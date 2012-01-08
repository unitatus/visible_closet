class CompleteDimensionsRefactor < ActiveRecord::Migration
  def self.up
    remove_column :boxes, :length
    remove_column :boxes, :width
    remove_column :boxes, :height
    remove_column :boxes, :location
    remove_column :stored_items, :length
    remove_column :stored_items, :width
    remove_column :stored_items, :height
    remove_column :stored_items, :location
    rename_column :dimension_sets, :new_length, :length
    rename_column :dimension_sets, :new_width, :width
    rename_column :dimension_sets, :new_height, :height
    rename_column :dimension_sets, :new_location, :location
  end

  def self.down
    rename_column :dimension_sets, :length, :new_length
    rename_column :dimension_sets, :width, :new_width
    rename_column :dimension_sets, :height, :new_height
    rename_column :dimension_sets, :location, :new_location
    add_column :boxes, :length, :float
    add_column :boxes, :width, :float
    add_column :boxes, :height, :float
    add_column :boxes, :location, :string
    add_column :stored_items, :length, :float
    add_column :stored_items, :width, :float
    add_column :stored_items, :height, :float
    add_column :stored_items, :location, :string
  end
end
