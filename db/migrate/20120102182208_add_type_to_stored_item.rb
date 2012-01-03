class AddTypeToStoredItem < ActiveRecord::Migration
  def self.up
    add_column :stored_items, :type, :string
  end

  def self.down
    remove_column :stored_items, :type
  end
end
