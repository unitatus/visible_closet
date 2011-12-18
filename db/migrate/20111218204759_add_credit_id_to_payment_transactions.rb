class AddCreditIdToPaymentTransactions < ActiveRecord::Migration
  def self.up
    add_column :payment_transactions, :credit_id, :integer, :references => :credits
  end

  def self.down
    remove_column :payment_transactions, :credit_id
  end
end
