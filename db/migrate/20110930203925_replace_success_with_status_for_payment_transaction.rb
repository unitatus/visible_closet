class ReplaceSuccessWithStatusForPaymentTransaction < ActiveRecord::Migration
  def self.up
    add_column :payment_transactions, :status, :string
    PaymentTransaction.all.each do |payment|
      if payment.success?
        payment.update_attribute(:status, PaymentTransaction::SUCCESS_STATUS)
      else
        payment.update_attribute(:status, PaymentTransaction::FAILURE_STATUS)
      end
    end
    remove_column :payment_transactions, :success
  end

  def self.down
    add_column :payment_transactions, :success, :boolean
    PaymentTransaction.all.each do |payment|
      payment.update_attribute(:success, payment.success?)
    end
    remove_column :payment_transaction, :status
  end
end
