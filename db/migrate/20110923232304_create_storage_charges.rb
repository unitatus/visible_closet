class CreateStorageCharges < ActiveRecord::Migration
  def self.up
    create_table :storage_charges do |t|
      t.integer :box_id, :references => :boxes
      t.integer :charge_id, :references => :charges
      t.integer :subscription_id, :references => :subscriptions
      t.datetime :start_date
      t.datetime :end_date
    end
  end

  def self.down
    drop_table :storage_charges
  end
end
