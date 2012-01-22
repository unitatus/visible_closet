class AddCouponToOffer < ActiveRecord::Migration
  def self.up
    add_column :coupons, :offer_id, :integer, :references => :offers
  end

  def self.down
    remove_column :coupons, :offer_id
  end
end
