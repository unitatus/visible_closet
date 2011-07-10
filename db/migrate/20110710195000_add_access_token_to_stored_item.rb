class AddAccessTokenToStoredItem < ActiveRecord::Migration
  def self.up
    add_column :stored_items, :access_token, :string
  end

  def self.down
    remove_column :stored_items, :access_token
  end
end
