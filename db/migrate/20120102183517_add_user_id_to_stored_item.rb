class AddUserIdToStoredItem < ActiveRecord::Migration
  def self.up
    add_column :stored_items, :user_id, :integer, :references => :users
  end

  def self.down
    remove_column :stored_items, :user_id
  end
end
