class AddSignupCommentsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :signup_comments, :text
  end

  def self.down
    remove_column :users, :signup_comments
  end
end
