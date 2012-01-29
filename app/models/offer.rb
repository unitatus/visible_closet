# == Schema Information
# Schema version: 20120122173933
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
#  active             :boolean
#

class Offer < ActiveRecord::Base  
  validates_presence_of :unique_identifier, :message => "can't be blank", :unless => :identifier_overridden
  validates_uniqueness_of :unique_identifier, :message => "this identifier is not unique!", :unless => :identifier_overridden
  
  belongs_to :creator, :class_name => "User", :foreign_key => :created_by_user_id
  has_many :benefits, :dependent => :destroy, :autosave => true, :class_name => "OfferBenefit"
  has_many :user_offers, :dependent => :destroy
  
  validates_presence_of :start_date, :message => "can't be blank"
  validates_presence_of :expiration_date, :message => "can't be blank"
  validates_presence_of :creator, :message => "must specify creating administrator"
  
  validate :start_date_lte_exp_date
  validate :at_least_one_benefit
  
  def Offer.new(attrs=nil)
    return_val = super(attrs)
    return_val.active = false
    return return_val
  end
  
  def current?
    start_date && expiration_date && start_date <= Time.now && expiration_date >= Time.now
  end
  
  def has_users?
    return user_offers.any?
  end
  
  def benefits_description
    return_str = ""
    
    benefits.each do |benefit|
      return_str += benefit.description
    end
    
    return return_str
  end
  
  def associate_with(user)
    user_offer = UserOffer.new
    
    user_offer.user = user
    user_offer.offer = self
    
    benefits.each do |benefit|
      user_offer.user_offer_benefits << benefit.build_user_offer_benefit
    end
    
    user_offer.save
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
  
  def at_least_one_benefit
    if benefits.empty?
      errors.add(:benefits, "must have at least one benefit defined")
    end
  end
end
