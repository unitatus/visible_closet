class AddCouponIdToUserOffer < ActiveRecord::Migration
  def self.up
    add_column :user_offers, :coupon_id, :integer, :references => :coupons
  end

  def self.down
    remove_column :user_offers, :coupon_id
  end
end
