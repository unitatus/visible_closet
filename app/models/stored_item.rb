# == Schema Information
# Schema version: 20110624000133
#
# Table name: stored_items
#
#  id         :integer         not null, primary key
#  box_id     :integer
#  created_at :datetime
#  updated_at :datetime
#

class StoredItem < ActiveRecord::Base
  belongs_to :boxes
  has_many :photos
end
