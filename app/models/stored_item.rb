# == Schema Information
# Schema version: 20111127181642
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
#  status             :string(255)
#  donated_to         :string(255)
#  shipment_id        :integer
#

class StoredItem < ActiveRecord::Base
  IN_STORAGE_STATUS = :in_storage_status
  DONATION_REQUESTED_STATUS = :donation_requested
  DONATED_STATUS = :donated
  MAILING_REQUESTED_STATUS = :mailing_requested
  MAILED_STATUS = :mailed
  
  symbolize :status
  
  belongs_to :box
  belongs_to :shipment
  has_many :stored_item_tags, :dependent => :destroy
  has_many :service_order_lines, :class_name => 'OrderLine'
  attr_accessible :file
  before_create :generate_access_token
  
  has_attached_file :photo, :styles => { 
                              :thumb => "100x100#",
                              :normal => "600x600>",
                              :medium => "150x150>" 
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
  
  def StoredItem.new()
    stored_item = super
    stored_item.status = IN_STORAGE_STATUS
    stored_item
  end
  
  def StoredItem.count_items(user)
    count_by_sql "SELECT COUNT(*) FROM stored_items s, boxes b WHERE s.box_id = b.id AND b.assigned_to_user_id = #{user.id}"
  end
  
  def StoredItem.find_all_by_assigned_to_user_id(user_id, box_id=nil)
    box_conditions = { :assigned_to_user_id => user_id }
    
    if !box_id.blank?
      box_conditions[:id] = box_id
    end
    
    all(:joins => :box, :conditions => { :boxes => box_conditions }, :order => "created_at ASC" )
  end
  
  def StoredItem.tags_search(tags, user, json_ready=true)
    conditions = Array.new
    conditions[0] = "boxes.assigned_to_user_id = ? AND ("
    conditions << user.id.to_s
    
    tags.each_with_index do |tag, index|
      if (index > 0)
        conditions[0] += " or "
      end
      conditions[0] += "UPPER(tag) like UPPER(?)"
      conditions << "%" + tag + "%"
    end
    
    conditions[0] += ")"
    
    matching_tags = StoredItemTag.joins("INNER JOIN stored_items ON stored_item_tags.stored_item_id = stored_items.id INNER JOIN boxes ON stored_items.box_id = boxes.id " \
      + "WHERE " + sanitize_sql_array(conditions))
    grouped_item_tags = Hash.new
    item_counts = Hash.new # used to narrow down the search; tricky in rails to find only the items with both matches and pull back the tags too all in SQL
    
    matching_tags.each do |stored_item_tag|
      if grouped_item_tags[stored_item_tag.stored_item_id].nil?
        grouped_item_tags[stored_item_tag.stored_item_id] = ""
        item_counts[stored_item_tag.stored_item_id] = 0
      end
      
      grouped_item_tags[stored_item_tag.stored_item_id] += stored_item_tag.tag + " "
      item_counts[stored_item_tag.stored_item_id] = item_counts[stored_item_tag.stored_item_id] + 1
    end
    
    # select only the records that match all tags
    grouped_item_tags.delete_if { |stored_item_id, tag_str| item_counts[stored_item_id] < tags.size }
    
    # Rails does not support joining and eager loading, so this is to seed the cache for faster processing. -DZ
    # For those following along from home, we do a search for stored items matching the ids in the grouped_item_tags keys, tell Rails to fetch the boxes while
    # we're at it and put them in the Rails cache, turn the resulting array of stored items into an array with each entry an array of id and stored item,
    # convert that into an array of id's followed by stored items (with flatten), convert that into the parameters to a function call using *, and pass that to the
    # array method on Hash that converts an even-sized array into a hash of key-value pairs. Whew!
    cache = Hash[*StoredItem.includes(:box).where(:id => grouped_item_tags.keys).all.collect { |item| [item.id, item]}.flatten]
    
    if json_ready
      grouped_item_tags.keys.collect do |stored_item_id|
        { :id => stored_item_id, :tag_matches => grouped_item_tags[stored_item_id], :box_num => cache[stored_item_id].box.box_num, \
          :img => cache[stored_item_id].photo.url(:thumb), :donated => cache[stored_item_id].donated?, :donated_to => cache[stored_item_id].donated_to }
      end
    else
      cache.values
    end
  end
  
  # this method hits the database every time. If you are going to call it a lot on the same object consider calling box.user.
  # Note that the stored items are found once each; Rails caches them.
  def StoredItem.find_by_id_and_user_id(stored_item_id, user_id)
    joins(:box).where("boxes.assigned_to_user_id = #{user_id} AND stored_items.id = #{stored_item_id}").first
  end
  
  def process_service(product)
    if product.id == Rails.application.config.item_donation_product_id
      update_attribute(:status, DONATION_REQUESTED_STATUS)
    elsif product.id == Rails.application.config.item_mailing_product_id
      update_attribute(:status, MAILING_REQUESTED_STATUS)
    else
      raise "Invalid product id for item service product: " + product.id.to_s
    end
  end
  
  def finalize_service(product, charity_name=nil, shipment=nil)
    if product.id == Rails.application.config.item_donation_product_id
      update_attribute(:status, DONATED_STATUS)
      update_attribute(:donated_to, charity_name)
    elsif product.id == Rails.application.config.item_mailing_product_id
      update_attribute(:status, MAILED_STATUS)
      self.shipment = shipment
      save
    else
      raise "Invalid product id for item service product: " + product.id.to_s
    end
  end
  
  def donated?
    status == DONATED_STATUS
  end
  
  def service_status?
    status == DONATED_STATUS || status == DONATION_REQUESTED_STATUS || status == MAILING_REQUESTED_STATUS || status == MAILED_STATUS
  end
  
  def mailed?
    status == MAILED_STATUS
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
end
