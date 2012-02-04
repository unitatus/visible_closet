# == Schema Information
# Schema version: 20120204200541
#
# Table name: user_offers
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  offer_id   :integer
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  coupon_id  :integer
#

class UserOffer < ActiveRecord::Base
  belongs_to :user
  belongs_to :offer
  has_many :user_offer_benefits, :dependent => :destroy
  belongs_to :coupon

  # Want to show the offer information in its entirety
  def method_missing(meth, *args, &blk)
    meth.to_s == 'id' ? super : offer.send(meth, *args, &blk)
  rescue NoMethodError
    super
  end
  
  def unique_identifier
    if coupon
      coupon.unique_identifier
    else
      offer.unique_identifier
    end
  end
  
  def benefit_used_messages
    # have to flatten because each user offer benefit will return an array; without flatten we'll have an array of arrays
    user_offer_benefits.collect {|user_offer_benefit| user_offer_benefit.benefit_used_messages }.flatten
  end
  
  def benefit_remaining_messages
    # have to flatten because each user offer benefit will return an array; without flatten we'll have an array of arrays
    user_offer_benefits.collect {|user_offer_benefit| user_offer_benefit.benefit_remaining_messages }.flatten
  end
  
  def used?
    user_offer_benefits.select {|user_offer_benefit| user_offer_benefit.used? }.any?
  end
  
  def applies_to_boxes?
    user_offer_benefits.select {|user_offer_benefit| user_offer_benefit.applies_to_boxes? }.any?
  end
  
  def applied_boxes
    user_offer_benefits.collect {|user_offer_benefit| user_offer_benefit.applies_to_boxes? ? user_offer_benefit.applied_boxes : nil}.flatten.compact
  end
  
  def applied_to_box?(box)
    user_offer_benefits.select {|user_offer_benefit| user_offer_benefit.applied_to_box?(box) }.any?
  end
  
  def discounted_for_box?(box)
    user_offer_benefits.select {|user_offer_benefit| user_offer_benefit.discounted_for_box?(box) }.any?
  end
  
  def assign_boxes(box_ids)
    box_ids = Array.new if box_ids.nil?
    
    # For now we make the assumption that an offer only has one benefit that applies to boxes
    box_benefit = user_offer_benefits.select {|user_offer_benefit| user_offer_benefit.applies_to_boxes? }.last
    if box_benefit.nil?
      return true
    end
    
    total_box_potential = offer.total_box_potential
    
    if box_ids.size > total_box_potential
      errors.add(:user_offer, "Cannot add more than #{total_box_potential} #{total_box_potential > 1 ? 'boxes' : 'box' }.") and return false
    end
    boxes = Box.find(box_ids)
    
    box_benefit.remove_modifiable_boxes
    box_benefit.reload
    
    boxes.each do |box|
      box_benefit.associate_with(box)
    end
    
    return true
  end
  
  def can_modify_boxes?
    user_offer_benefits.select {|box_benefit| box_benefit.respond_to?(:can_modify_boxes?) && box_benefit.can_modify_boxes? }.any?
  end
  
  def applied_to_boxes?
    user_offer_benefits.select {|box_benefit| box_benefit.respond_to?(:applied_to_boxes?) && box_benefit.applied_to_boxes? }.any?
  end
end
