class AddStatusToStoredItem < ActiveRecord::Migration
  def self.up
    add_column :stored_items, :status, :string
  end

  def self.down
    remove_column :stored_items, :status
  end
end
