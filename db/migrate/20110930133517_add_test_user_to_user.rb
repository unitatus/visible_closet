class AddTestUserToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :test_user, :boolean
  end

  def self.down
    remove_column :users, :test_user
  end
end
