# == Schema Information
# Schema version: 20110710193520
#
# Table name: stored_items
#
#  id                 :integer         not null, primary key
#  box_id             :integer
#  created_at         :datetime
#  updated_at         :datetime
#  photo_file_name    :string(255)
#  photo_content_type :string(255)
#  photo_file_size    :integer
#  photo_updated_at   :datetime
#

class StoredItem < ActiveRecord::Base
  belongs_to :boxes
  attr_accessible :file
  
  has_attached_file :photo, :styles => { 
                              :thumb => "100x100#",
                              :normal => "600x600>", 
                              },
                            :url => "/system/photos/:id/:style.:extension",
                            :path => ":rails_root/public/system/photos/:id/:style.:extension"
                            
  validates_attachment_presence :photo
  validates_attachment_content_type :photo, :content_type => [/image\/jpg/, /image\/jpeg/, /image\/pjpeg/, /image\/gif/, /image\/png/, /image\/x-png/]
  
end
