class CleanUpStorageCharge < ActiveRecord::Migration
  def self.up
    remove_column :storage_charges, :subscription_id
    remove_column :charges, :box_id
  end

  def self.down
    add_column :storage_charges, :subscription_id, :integer, :references => :subscriptions
    add_column :charges, :box_id, :integer, :references => :boxes
  end
end
