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

  attr_accessible :tag
end
