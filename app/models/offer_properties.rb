# == Schema Information
# Schema version: 20120122013834
#
# Table name: offer_properties
#
#  id                 :integer         not null, primary key
#  start_date         :datetime
#  expiration_date    :datetime
#  created_by_user_id :integer
#  unique_identifier  :string(255)
#  offer_id           :integer
#  offer_type         :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

class OfferProperties < ActiveRecord::Base
  belongs_to :offer, :polymorphic => true
  belongs_to :creator, :class_name => "User", :foreign_key => :created_by_user_id
  has_many :benefits, :dependent => :destroy, :class_name => "OfferBenefit"
  
  validates_presence_of :start_date, :message => "can't be blank"
  validates_presence_of :expiration_date, :message => "can't be blank"
  validates_presence_of :creator, :message => "must specify creating administrator"
  validates_presence_of :unique_identifier, :message => "can't be blank"
  validates_uniqueness_of :unique_identifier, :message => "this identifier is not unique!"
  
  validate :start_date_lte_exp_date
  
  protected
  
  def start_date_lte_exp_date
    if start_date && expiration_date && start_date > expiration_date
      errors.add(:start_date, "start date must precede expiration date")
      errors.add(:expiration_date, "start date must precede expiration date")
    end
  end
end
