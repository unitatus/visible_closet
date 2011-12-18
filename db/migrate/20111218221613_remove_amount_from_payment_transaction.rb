class RemoveAmountFromPaymentTransaction < ActiveRecord::Migration
  def self.up
    remove_column :payment_transactions, :amount
    transactions = PaymentTransaction.all
    transactions.each do |transaction|
      transaction.amount = transaction.back_up_amount
      transaction.save
      transaction.credit.created_at = transaction.created_at
      transaction.credit.save
    end
  end

  def self.down
    add_column :payment_transactions, :amount, :float
    transactions = PaymentTransaction.all
    transactions.each do |transaction|
      transaction.set_old_amount(transaction.back_up_amount)
      transaction.save
    end
  end
end
