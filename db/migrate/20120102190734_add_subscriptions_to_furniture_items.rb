:lass AddSubscriptionsToFurnitureItems < ActiveRecord::Migration
  def self.up
    create_table :furniture_items_subscriptions, :id => false do |t|
          t.integer :furniture_item_id, :references => :stored_items
          t.integer :subscription_id, :references => :subscriptions
    end
    
    add_index :furniture_items_subscriptions, :furniture_item_id
    add_index :furniture_items_subscriptions, :subscription_id
  end

  def self.down
    drop_table :furniture_items_subscriptions
  end
end
