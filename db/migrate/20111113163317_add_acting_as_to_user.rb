class AddActingAsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :acting_as_user_id, :integer, :references => :users
  end

  def self.down
    remove_column :users, :acting_as_user_id
  end
end
