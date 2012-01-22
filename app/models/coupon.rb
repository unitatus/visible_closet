# == Schema Information
# Schema version: 20120122060545
#
# Table name: coupons
#
#  id                  :integer         not null, primary key
#  assigned_to_user_id :integer
#  unique_identifier   :string(255)
#  offer_id            :integer
#  offer_type          :string(255)
#

class Coupon < ActiveRecord::Base  
  belongs_to :user, :foreign_key => :assigned_to_user_id
  belongs_to :offer, :foreign_key => :offer_id, :class_name => "CouponOffer"
  
  def user=(new_user)
    if user
      raise "Cannot change user for coupon."
    else
      super(new_user)
    end
  end
end
