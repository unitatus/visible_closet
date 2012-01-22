# == Schema Information
# Schema version: 20120122023727
#
# Table name: free_storage_benefit_properties
#
#  id               :integer         not null, primary key
#  offer_benefit_id :integer
#  num_boxes        :integer
#  num_months       :integer
#

class FreeStorageBenefitProperties < ActiveRecord::Base
  belongs_to :free_storage_offer_benefit
  
  validates_presence_of :num_boxes, :message => "cannot be blank"
  validates_numericality_of :num_boxes, :message => "must be an integer"
  validates_presence_of :num_months, :message => "cannot be blank"
  validates_numericality_of :num_months, :message => "must be an integer"
end
