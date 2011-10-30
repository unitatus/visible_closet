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
  
  # this method hits the database every time. If you are going to call it a lot on the same object consider calling box.user.
  # Note that the stored items are found once each; Rails caches them.
  def StoredItemTag.find_by_id_and_user_id(tag_id, user_id)
    joins(:stored_item).joins(:box).where("boxes.assigned_to_user_id = #{user_id} AND stored_item_tags.id = #{tag_id}").first
  end
end
