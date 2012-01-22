class DropCouponOffer < ActiveRecord::Migration
  def self.up
    drop_table :coupon_offers
  end

  def self.down
    create_table :coupon_offers do |t|
      t.timestamps
    end
  end
end
