# == Schema Information
# Schema version: 20110710023401
#
# Table name: stored_items
#
#  id                :integer         not null, primary key
#  box_id            :integer
#  created_at        :datetime
#  updated_at        :datetime
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#

class StoredItem < ActiveRecord::Base
  belongs_to :boxes
  attr_accessible :file
  
  has_attached_file :file, :styles => { 
                              :thumb => "100x100#",
                              :normal => "600x600>", 
                              },
                            :url => "/system/photos/:id/:style.:extension",
                            :path => ":rails_root/public/system/photos/:id/:style.:extension"
                            
  validates_attachment_presence :file
  validates_attachment_content_type :file, :content_type => [/image\/jpg/, /image\/jpeg/, /image\/pjpeg/, /image\/gif/, /image\/png/, /image\/x-png/]
  
end
