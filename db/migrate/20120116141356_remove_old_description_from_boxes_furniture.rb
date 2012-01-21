class RemoveOldDescriptionFromBoxesFurniture < ActiveRecord::Migration
  def self.up
    remove_column :boxes, :old_description
    remove_column :stored_items, :old_description
  end

  def self.down
    add_column :boxes, :old_description, :string
    add_column :stored_items, :old_description, :string
  end
end
