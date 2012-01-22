# == Schema Information
# Schema version: 20120122013834
#
# Table name: offers
#
#  id :integer         not null, primary key
#

class Offer < ActiveRecord::Base
  include HasOfferProperties
end
