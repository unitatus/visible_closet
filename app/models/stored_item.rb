# == Schema Information
# Schema version: 20110710195000
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
#  access_token       :string(255)
#

class StoredItem < ActiveRecord::Base
  belongs_to :box
  has_many :stored_item_tags
  attr_accessible :file
  before_create :generate_access_token
  
  has_attached_file :photo, :styles => { 
                              :thumb => "100x100#",
                              :normal => "600x600>",
                              :medium => "200x200>" 
                              },
                            :storage => :s3,
                            :s3_credentials => { 
                                  :access_key_id => Rails.application.config.s3_key,
                                  :secret_access_key => Rails.application.config.s3_secret
                                },
                            :s3_protocol => :https,
                            :path => Rails.application.config.s3_photo_path,
                            :bucket => Rails.application.config.s3_photo_bucket

                            
  validates_attachment_presence :photo
  validates_attachment_content_type :photo, :content_type => [/image\/jpg/, /image\/jpeg/, /image\/pjpeg/, /image\/gif/, /image\/png/, /image\/x-png/]
  
  def StoredItem.count_items(user)
    count_by_sql "SELECT COUNT(*) FROM stored_items s, boxes b WHERE s.box_id = b.id AND b.assigned_to_user_id = #{user.id}"
  end
  
  private
  
  # simple random salt
  def random_salt(len = 20)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    salt = ""
    1.upto(len) { |i| salt << chars[rand(chars.size-1)] }
    return salt
  end

  # SHA1 from random salt and time
  def generate_access_token
    self.access_token = Digest::SHA1.hexdigest("#{random_salt}#{Time.now.to_i}")
  end

  # interpolate in paperclip
  Paperclip.interpolates :access_token  do |attachment, style|
    attachment.instance.access_token
  end
      
  def StoredItem.find_all_by_assigned_to_user_id(user_id, box_id=nil)
    box_conditions = { :assigned_to_user_id => user_id }
    
    if !box_id.blank?
      box_conditions[:id] = box_id
    end
    
    all(:joins => :box, :conditions => { :boxes => box_conditions } )
  end
end
