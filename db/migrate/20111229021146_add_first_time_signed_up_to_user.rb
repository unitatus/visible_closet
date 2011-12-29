class AddFirstTimeSignedUpToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :first_time_signed_up, :boolean
    users = User.all
    users.each do |user|
      user.first_time_signed_up = false
      user.save
    end
  end

  def self.down
    remove_column :users, :first_time_signed_up
  end
end
