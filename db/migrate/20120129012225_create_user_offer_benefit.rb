class CreateUserOfferBenefit < ActiveRecord::Migration
  def self.up
    create_table :user_offer_benefits do |t|
      t.integer :user_offer_id, :references => :user_offers
      t.integer :offer_benefit_id, :references => :offer_benefits
      t.string :type
      t.timestamps
    end
  end

  def self.down
    drop_table :user_offer_benefits
  end
end
