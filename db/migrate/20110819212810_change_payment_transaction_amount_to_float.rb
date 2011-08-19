class ChangePaymentTransactionAmountToFloat < ActiveRecord::Migration
  def self.up
    change_table :payment_transactions do |t|
      t.change :amount, :float
    end

  end

  def self.down
    change_table :payment_transactions do |t|
      t.change :amount, :integer
    end
  end
end
