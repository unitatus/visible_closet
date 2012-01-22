# == Schema Information
# Schema version: 20120122055753
#
# Table name: offer_benefits
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  offer_id   :integer
#

class OfferBenefit < ActiveRecord::Base
  belongs_to :offer_properties
  
  # No such thing as "belongs to through"
  def offer
    self.offer_properties.nil? ? nil : self.offer_properties.offer
  end
  
  # No such thing as "belongs to through"
  def offer=(offer)
    if offer.nil?
      self.offer_properties = nil
    else
      self.offer_properties = offer.offer_properties
    end
  end
end
