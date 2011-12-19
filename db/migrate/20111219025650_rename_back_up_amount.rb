class RenameBackUpAmount < ActiveRecord::Migration
  def self.up
    rename_column :payment_transactions, :back_up_amount, :submitted_amount
    credits = Credit.all
    credits.each do |credit|
      if credit.payment_transaction && credit.payment_transaction.status != PaymentTransaction::SUCCESS_STATUS
        credit.destroy
      end
    end
  end

  def self.down
    rename_column :payment_transactions, :submitted_amount, :back_up_amount
  end
end
