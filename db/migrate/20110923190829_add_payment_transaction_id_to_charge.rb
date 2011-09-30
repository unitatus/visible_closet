class AddPaymentTransactionIdToCharge < ActiveRecord::Migration
  def self.up
    add_column :charges, :payment_transaction_id, :integer, :references => :payment_transactions
    Order.all.each do |order|
      if order.payment_transactions.size > 0
        order.charges.each do |charge|
          charge.update_attribute(:payment_transaction_id, order.payment_transactions[0].id);
        end
      end
    end
  end

  def self.down
    remove_column :charges, :payment_transaction_id
  end
end
