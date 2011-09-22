# == Schema Information
# Schema version: 20110717194124
#
# Table name: stored_item_tags
#
#  id             :integer         not null, primary key
#  stored_item_id :integer
#  tag            :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

class StoredItemTag < ActiveRecord::Base
  belongs_to :stored_item
  # This isn't strictly true -- a stored item tag can only have one box -- but Rails doesn't support belongs_to through, so we can't do a join otherwise. -DZ
  has_many :boxes, :through => :stored_item

  attr_accessible :tag
end
