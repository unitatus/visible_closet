class AddToCreditOfferRelationship < ActiveRecord::Migration
  def self.up
    create_table :free_storage_user_offer_benefit_box_credits do |t|
      t.integer :free_storage_user_offer_benefit_box_id, :references => :free_storage_user_offer_benefit_boxes
      t.integer :credit_id, :references => :credits
      t.integer :days_consumed
      t.timestamps
    end
  end

  def self.down
    drop_table :free_storage_user_offer_benefit_box_credits
  end
end
