# == Schema Information
# Schema version: 20110627180233
#
# Table name: products
#
#  id            :integer         not null, primary key
#  name          :string(255)
#  price         :integer
#  created_at    :datetime
#  updated_at    :datetime
#  price_comment :string(255)
#

class Product < ActiveRecord::Base
  attr_accessible :id, :name, :price, :price_comment, :created_at, :updated_at
end
