class RefactorOffers < ActiveRecord::Migration
  def self.up
    remove_column :offer_properties, :unique_identifier
    add_column :offers, :unique_identifier, :string
    add_column :coupons, :unique_identifier, :string
    add_index :offers, :unique_identifier
    add_index :coupons, :unique_identifier
    create_table :coupon_offers do |t|
      t.timestamps
    end
  end

  def self.down
    add_column :offer_properties, :unique_identifier, :string
    add_index :offer_properties, :unique_identifier
    remove_column :offers, :unique_identifier
    remove_column :coupons, :unique_identifier
    drop_table :coupon_offers
  end
end
