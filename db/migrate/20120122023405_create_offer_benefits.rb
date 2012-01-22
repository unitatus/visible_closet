class CreateOfferBenefits < ActiveRecord::Migration
  def self.up
    create_table :offer_benefits do |t|
      t.integer :offer_properties_id, :references => :offer_properties
      t.string :type
      t.timestamps
    end
  end

  def self.down
    drop_table :offer_benefits
  end


end
