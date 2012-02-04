# == Schema Information
# Schema version: 20120204201152
#
# Table name: coupons
#
#  id                :integer         not null, primary key
#  unique_identifier :string(255)
#  offer_id          :integer
#  offer_type        :string(255)
#

class Coupon < ActiveRecord::Base  
  require 'rufus/mnemo'
  
  belongs_to :offer, :foreign_key => :offer_id, :class_name => "CouponOffer"
  has_one :user_offer

  validates_presence_of :unique_identifier
  validates_uniqueness_of :unique_identifier
  
  # Want to show the offer information in its entirety
  def method_missing(meth, *args, &blk)
    meth.to_s == 'id' || meth.to_s == 'unique_identifier' || meth.to_s == 'associate_with' ? super : (user_offer.nil? ? offer.send(meth, *args, &blk) : user_offer.send(meth, *args, &blk))
  rescue NoMethodError
    super
  end
  
  def associate_with(user)
    user_offer = offer.associate_with(user)
    user_offer.coupon = self
    user_offer.save
  end
  
  def user
    user_offer ? user_offer.user : nil
  end
  
  protected
    def before_validation
      # self.unique_identifier = rand(36**8).to_s(36) if self.new_record? and self.unique_identifier.nil?
      self.unique_identifier = Rufus::Mnemo::from_integer rand(36**8) if self.unique_identifier.nil?
    end
end
