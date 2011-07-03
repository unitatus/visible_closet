# == Schema Information
# Schema version: 20110624203839
#
# Table name: photos
#
#  id                :integer         not null, primary key
#  stored_item_id    :integer
#  created_at        :datetime
#  updated_at        :datetime
#  data_file_name    :string(255)
#  data_content_type :string(255)
#  data_file_size    :integer
#  data_updated_at   :datetime
#

class Photo < ActiveRecord::Base
  belongs_to :stored_items

  has_attached_file :data,
    :styles => {
      :thumb => "50x50#",
      :large => "640X480#"
    }

  validates_attachment_presence :data
  validates_attachment_content_type :data,
    :content_type => ['image/jpeg', 'image/pjpeg', 'image/jpg', 'image/png', 'image/png']
end
