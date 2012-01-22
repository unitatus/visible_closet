# == Schema Information
# Schema version: 20120122055753
#
# Table name: offers
#
#  id                 :integer         not null, primary key
#  unique_identifier  :string(255)
#  start_date         :datetime
#  expiration_date    :datetime
#  created_by_user_id :integer
#  type               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

class Offer < ActiveRecord::Base  
  validates_presence_of :unique_identifier, :message => "can't be blank", :unless => :identifier_overridden
  
  belongs_to :creator, :class_name => "User", :foreign_key => :created_by_user_id
  has_many :benefits, :dependent => :destroy, :class_name => "OfferBenefit"
  
  validates_presence_of :start_date, :message => "can't be blank"
  validates_presence_of :expiration_date, :message => "can't be blank"
  validates_presence_of :creator, :message => "must specify creating administrator"
  validates_uniqueness_of :unique_identifier, :message => "this identifier is not unique!"
  
  validate :start_date_lte_exp_date
  
  def current?
    start_date && expiration_date && start_date <= Time.now && expiration_date >= Time.now
  end
  
  protected
  
  def start_date_lte_exp_date
    if start_date && expiration_date && start_date > expiration_date
      errors.add(:start_date, "start date must precede expiration date")
      errors.add(:expiration_date, "start date must precede expiration date")
    end
  end
  
  def identifier_overridden
    false
  end
end
