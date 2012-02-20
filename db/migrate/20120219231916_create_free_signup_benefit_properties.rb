class CreateFreeSignupBenefitProperties < ActiveRecord::Migration
  def self.up
    create_table :free_signup_benefit_properties do |t|
      t.integer :free_signup_offer_benefit_id, :references => :offer_benefits
      t.integer :num_boxes
    end
    
  end

  def self.down
    drop_table :free_signup_benefit_properties
  end
end
