class AddAuthTransactionIdToPaymentTransaction < ActiveRecord::Migration
  def self.up
    add_column :payment_transactions, :auth_transaction_id, :string
  end

  def self.down
    remove_column :payment_transactions, :auth_transaction_id
  end
end
