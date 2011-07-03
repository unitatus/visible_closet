class CreatePaymentTransactions < ActiveRecord::Migration
  def self.up
    create_table :payment_transactions do |t|
      t.integer :order_id, :references => :orders
      t.string :action
      t.integer :amount
      t.boolean :success
      t.string :authorization
      t.string :message
      t.text :params
      t.integer :user_id, :references => :users

      t.timestamps
    end
 
    add_index :payment_transactions, :order_id
    add_index :payment_transactions, :user_id
  end

  def self.down
    drop_table :payment_transactions
  end
end
