class CreateOfferProperties < ActiveRecord::Migration
  def self.up
    create_table :offer_properties do |t|
      t.datetime :start_date
      t.datetime :expiration_date
      t.integer :created_by_user_id, :references => :users
      t.string :unique_identifier
      t.integer :offer_id
      t.string :offer_type
      t.timestamps
    end
  end

  def self.down
    drop_table :offer_properties
  end

end
