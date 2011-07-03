class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders do |t|
      t.integer :cart_id
      t.string :ip_address
      t.integer :user_id, :references => :users

      t.timestamps
    end

    add_index :orders, :cart_id
    add_index :orders, :user_id
  end

  def self.down
    drop_table :orders
  end
end
