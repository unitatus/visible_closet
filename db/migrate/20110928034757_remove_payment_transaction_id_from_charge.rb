class RemovePaymentTransactionIdFromCharge < ActiveRecord::Migration
  def self.up
    remove_column :charges, :payment_transaction_id
  end

  def self.down
    add_column :charges, :payment_transaction_id, :integer, :references => :payment_transactions
  end
end
