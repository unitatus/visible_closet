class AddBackUpAmountToPaymentTransaction < ActiveRecord::Migration
  def self.up
    add_column :payment_transactions, :back_up_amount, :float
    transactions = PaymentTransaction.all
    transactions.each do |transaction|
      transaction.update_attribute(:back_up_amount, transaction.read_attribute(:amount))
    end
  end

  def self.down
    remove_column :payment_transactions, :back_up_amount
  end
end
