class CreateUserOffers < ActiveRecord::Migration
  def self.up
    create_table :user_offers do |t|
      t.integer :user_id, :references => :users
      t.integer :offer_id, :references => :offers
      t.string :type
      t.timestamps
    end
  end

  def self.down
    drop_table :user_offers
  end
end
