# == Schema Information
# Schema version: 20120219231916
#
# Table name: free_signup_benefit_properties
#
#  id                           :integer         not null, primary key
#  free_signup_offer_benefit_id :integer
#  num_boxes                    :integer
#

class FreeSignupBenefitProperties < ActiveRecord::Base
  belongs_to :free_signup_offer_benefit
  
  validates_presence_of :num_boxes, :message => "cannot be blank"
  validates_numericality_of :num_boxes, :message => "must be an integer"
end
