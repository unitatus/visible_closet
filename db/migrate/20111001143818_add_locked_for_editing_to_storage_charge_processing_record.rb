class AddLockedForEditingToStorageChargeProcessingRecord < ActiveRecord::Migration
  def self.up
    add_column :storage_charge_processing_records, :locked_for_editing, :boolean
  end

  def self.down
    remove_column :storage_charge_processing_records, :locked_for_editing
  end
end
