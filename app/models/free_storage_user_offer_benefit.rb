# == Schema Information
# Schema version: 20120129012225
#
# Table name: user_offer_benefits
#
#  id               :integer         not null, primary key
#  user_offer_id    :integer
#  offer_benefit_id :integer
#  type             :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

class FreeStorageUserOfferBenefit < UserOfferBenefit
  has_many :free_storage_user_offer_benefit_boxes, :foreign_key => :user_offer_benefit_id, :dependent => :destroy
  belongs_to :user_offer
  # this is necessary because the parent won't instantiate the right class
  belongs_to :offer_benefit, :class_name => "FreeStorageOfferBenefit"
  
  def applies_to_boxes?
    true
  end
  
  def benefit_used_messages    
    free_storage_user_offer_benefit_boxes.collect {|box_benefit| box_benefit.start_date.nil? \
      ? nil \
      : "#{box_benefit.days_consumed.to_i} days consumed of #{box_benefit.days_consumable.to_i}-day potential (start date #{box_benefit.start_date.strftime '%m/%d/%Y'}) for box #{box_benefit.box.box_num}" }.compact
  end
  
  def benefit_remaining_messages
    num_months = offer_benefit.num_months
    num_boxes = offer_benefit.num_boxes
    
    months_str = num_months == 1 ? "month" : "months"
    boxes_str = num_boxes == 1 ? "box" : "boxes"
    
    return_arr = free_storage_user_offer_benefit_boxes.collect {|box_benefit| 
      if box_benefit.benefit_remaining?
        if box_benefit.started? 
          "#{box_benefit.days_remaining.to_i} days of storage for box #{box_benefit.box.box_num}"
        else
          "#{num_months} #{months_str} storage for box #{box_benefit.box.box_num}"
        end
      else
        nil
      end
    }.compact
    
    if free_storage_user_offer_benefit_boxes.size < num_boxes
      return_arr << "#{num_months} #{months_str} for #{num_boxes - free_storage_user_offer_benefit_boxes.size} #{boxes_str}"
    end
    
    return return_arr
  end
  
  def used?
    free_storage_user_offer_benefit_boxes.select {|offer_benefit| offer_benefit.used? }.any?
  end
  
  def applied_boxes
    free_storage_user_offer_benefit_boxes.collect {|offer_benefit_box| offer_benefit_box.box }
  end
  
  def applied_to_box?(box)
    !relationship_for(box).nil?
  end
  
  def relationship_for(box)
    free_storage_user_offer_benefit_boxes.select {|offer_benefit_box| offer_benefit_box.box == box }.first
  end
  
  def discounted_for_box?(box)
    relationship = relationship_for(box)
    
    relationship.nil? ? false : relationship.used?
  end
  
  def associate_with(box)
    if !applied_to_box?(box)
      free_storage_user_offer_benefit_boxes.create!(:box_id => box.id)
    end
  end
  
  def remove_modifiable_boxes
    free_storage_user_offer_benefit_boxes.each do |benefit_box|
      if !benefit_box.used?
        benefit_box.destroy
      end
    end
  end
  
  def can_modify_boxes?
    free_storage_user_offer_benefit_boxes.select {|benefit_box| !benefit_box.used? }.any? || free_storage_user_offer_benefit_boxes.size < offer_benefit.num_boxes
  end
  
  def applied_to_boxes?
    free_storage_user_offer_benefit_boxes.any?
  end
end
