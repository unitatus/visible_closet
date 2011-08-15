class AddSubscriptionIdToBoxes < ActiveRecord::Migration
  def self.up
    add_column :boxes, :subscription_id, :integer, :references => :subscriptions
  end

  def self.down
    remove_column :boxes, :subscription_id
  end
end
