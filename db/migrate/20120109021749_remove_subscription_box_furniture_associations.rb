class RemoveSubscriptionBoxFurnitureAssociations < ActiveRecord::Migration
  def self.up
    drop_table :furniture_items_subscriptions
    drop_table :boxes_subscriptions
  end

  def self.down
    create_table :furniture_items_subscriptions, :id => false do |t|
          t.integer :furniture_item_id, :references => :stored_items
          t.integer :subscription_id, :references => :subscriptions
    end

    add_index :furniture_items_subscriptions, :furniture_item_id
    add_index :furniture_items_subscriptions, :subscription_id
    
    create_table :boxes_subscriptions, :id => false do |t|
              t.integer :box_id, :references => :boxes
              t.integer :subscription_id, :references => :subscriptions
        end

        add_index :boxes_subscriptions, :box_id
        add_index :boxes_subscriptions, :subscription_id
    
  end
end
