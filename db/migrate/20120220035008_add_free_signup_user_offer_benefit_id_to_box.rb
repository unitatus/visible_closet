class AddFreeSignupUserOfferBenefitIdToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :free_signup_user_offer_benefit_id, :integer, :references => :user_offer_benefits
  end

  def self.down
    remove_column :boxes, :free_signup_user_offer_benefit_id
  end
end
