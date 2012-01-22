class AddCouponToOffer < ActiveRecord::Migration
  def self.up
    add_column :coupons, :offer_id, :integer, :references => :offers
    add_column :coupons, :offer_type, :string
  end

  def self.down
    remove_column :coupons, :offer_id
    remove_column :coupons, :offer_type
  end
end
