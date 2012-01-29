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
  require 'rufus/mnemo'
  
  belongs_to :user, :foreign_key => :assigned_to_user_id, :class_name => "User"
  belongs_to :offer, :foreign_key => :offer_id, :class_name => "CouponOffer"

  validates_presence_of :unique_identifier
  validates_uniqueness_of :unique_identifier
  
  # Want to show the offer information in its entirety
  def method_missing(meth, *args, &blk)
    meth.to_s == 'id' ? super : offer.send(meth, *args, &blk)
  rescue NoMethodError
    super
  end
  
  protected
    def before_validation
      # self.unique_identifier = rand(36**8).to_s(36) if self.new_record? and self.unique_identifier.nil?
      self.unique_identifier = Rufus::Mnemo::from_integer rand(36**8) if self.unique_identifer.nil?
    end
end
