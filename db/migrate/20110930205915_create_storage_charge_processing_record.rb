class CreateStorageChargeProcessingRecord < ActiveRecord::Migration
  def self.up
    create_table :storage_charge_processing_records do |t|
      t.integer :generated_by_user_id, :references => :users
      t.datetime :as_of_date

      t.timestamps
    end
  end

  def self.down
    drop_table :storage_charge_processing_records
  end
end
