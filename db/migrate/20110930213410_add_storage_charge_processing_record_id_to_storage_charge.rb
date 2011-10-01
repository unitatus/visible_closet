class AddStorageChargeProcessingRecordIdToStorageCharge < ActiveRecord::Migration
  def self.up
    add_column :storage_charges, :storage_charge_processing_record_id, :integer, :references => :storage_charge_processing_records
    add_index :storage_charges, :storage_charge_processing_record_id, :name => 'storage_charge_scprid'
  end

  def self.down
    remove_column :storage_charges, :storage_charge_processing_record_id
  end
end
