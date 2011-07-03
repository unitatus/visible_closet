# == Schema Information
# Schema version: 20110624000133
#
# Table name: boxes
#
#  id                  :integer         not null, primary key
#  assigned_to_user_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#

class Box < ActiveRecord::Base
  attr_accessible :assigned_to_user_id

  has_many :stored_items
end
