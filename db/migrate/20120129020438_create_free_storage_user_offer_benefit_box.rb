class CreateFreeStorageUserOfferBenefitBox < ActiveRecord::Migration
  def self.up
    create_table :free_storage_user_offer_benefit_boxes do |t|
      t.integer :user_offer_benefit_id, :references => :user_offer_benefits
      t.integer :box_id, :references => :boxes
      t.float :months_consumed
      t.timestamps
    end
  end

  def self.down
    drop_table :free_storage_user_offer_benefit_boxes
  end
end
