class CreateFreeStorageBenefitProperties < ActiveRecord::Migration
  def self.up
    create_table :free_storage_benefit_properties do |t|
      t.integer :free_storage_offer_benefit_id, :references => :offer_benefits
      t.integer :num_boxes
      t.integer :num_months
    end
  end

  def self.down
    drop_table :free_storage_benefit_properties
  end
end
