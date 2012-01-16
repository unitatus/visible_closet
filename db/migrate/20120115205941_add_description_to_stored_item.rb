class AddDescriptionToStoredItem < ActiveRecord::Migration
  def self.up
    add_column :stored_items, :description, :string
  end

  def self.down
    remove_column :stored_items, :description
  end
end
