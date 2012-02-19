class AddStorageChargeProcessingRecordToCredit < ActiveRecord::Migration
  def self.up
    add_column :credits, :storage_charge_processing_record_id, :integer, :references => :storage_charge_processing_records
  end

  def self.down
    remove_column :credits, :storage_charge_processing_record_id
  end
end
