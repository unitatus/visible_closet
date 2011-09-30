class AddPaymentTransactionIdToCharge < ActiveRecord::Migration
  def self.up
    add_column :charges, :payment_transaction_id, :integer, :references => :payment_transactions
    
    # The create-drop bits are in case this needs to be re-executed with the current code, since heroku needed them (charges wouldn't load)
    create_table :storage_charges do |t|
      t.integer :box_id, :references => :boxes
      t.integer :charge_id, :references => :charges
      t.integer :subscription_id, :references => :subscriptions
      t.datetime :start_date
      t.datetime :end_date
    end
    Order.all.each do |order|
      if order.payment_transactions.size > 0
        order.charges.each do |charge|
          charge.update_attribute(:payment_transaction_id, order.payment_transactions[0].id);
        end
      end
    end
    drop_table :storage_charges
  end

  def self.down
    remove_column :charges, :payment_transaction_id
  end
end
