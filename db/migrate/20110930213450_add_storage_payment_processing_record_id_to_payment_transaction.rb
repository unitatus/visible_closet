class AddStoragePaymentProcessingRecordIdToPaymentTransaction < ActiveRecord::Migration
  def self.up
    add_column :payment_transactions, :storage_payment_processing_record_id, :integer, :references => :storage_payment_processing_records
    add_index :payment_transactions, :storage_payment_processing_record_id, :name => 'payment_transaction_spprid'
  end

  def self.down
    remove_column :payment_transactions, :storage_payment_processing_record_id
  end
end
