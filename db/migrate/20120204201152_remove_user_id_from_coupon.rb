class RemoveUserIdFromCoupon < ActiveRecord::Migration
  def self.up
    remove_column :coupons, :assigned_to_user_id
  end

  def self.down
    add_column :coupons, :assigned_to_user_id, :integer, :references => :users
  end
end
