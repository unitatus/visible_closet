# == Schema Information
# Schema version: 20120103033154
#
# Table name: stored_items
#
#  id                                    :integer         not null, primary key
#  box_id                                :integer
#  created_at                            :datetime
#  updated_at                            :datetime
#  status                                :string(255)
#  donated_to                            :string(255)
#  shipment_id                           :integer
#  type                                  :string(255)
#  height                                :float
#  width                                 :float
#  length                                :float
#  location                              :string(255)
#  creator_id                            :integer
#  user_id                               :integer
#  default_customer_stored_item_photo_id :integer
#  default_admin_stored_item_photo_id    :integer
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
  belongs_to :default_customer_photo, :foreign_key => :default_customer_stored_item_photo_id, :class_name => "StoredItemPhoto"
  belongs_to :default_admin_photo, :foreign_key => :default_admin_stored_item_photo_id, :class_name => "StoredItemPhoto"
  has_many :stored_item_tags, :dependent => :destroy
  has_many :service_order_lines, :class_name => 'OrderLine'
  
  # Note: height, width, length, location, user and creator exist only for subclass FurnitureItem
  attr_accessible :file, :access_token
  has_many :stored_item_photos, :dependent => :destroy, :order => "created_at"
  
  def StoredItem.new(attrs=nil)
    stored_item = super(attrs)
    stored_item.status = IN_STORAGE_STATUS
    stored_item
  end
  
  def stored_item_photo
    stored_item_photos.first
  end
  
  def photo
    stored_item_photo.photo
  end
  
  def user
    box.user
  end
  
  def default_photo(visibility)
    if visibility == StoredItemPhoto::CUSTOMER_VISIBILITY
      if default_customer_photo.nil?
        stored_item_photos_visibility(visibility).first
      else
        default_customer_photo
      end
    elsif visibility == StoredItemPhoto::ADMIN_VISIBILITY
      if default_admin_photo.nil?
        stored_item_photos_visibility(visibility).first
      else
        default_admin_photo
      end
    end
  end
  
  def stored_item_photos_visibility(visibility)
    stored_item_photos.select {|photo| photo.visibility == visibility }
  end
  
  def photos
    stored_item_photos
  end
  
  def StoredItem.count_items(user)
    count_by_sql "SELECT COUNT(*) FROM stored_items s, boxes b WHERE s.box_id = b.id AND b.assigned_to_user_id = #{user.id}"
  end
  
  def StoredItem.find_all_by_assigned_to_user_id(user_id, box_id=nil)
    box_conditions = { :assigned_to_user_id => user_id, :status => Box::IN_STORAGE_STATUS }
    
    if !box_id.blank?
      box_conditions[:id] = box_id
    end
    
    all(:joins => :box, :conditions => { :boxes => box_conditions }, :order => "created_at ASC" )
  end
  
  def StoredItem.tags_search(tags, user, json_ready=true)
    conditions = Array.new
    conditions[0] = "boxes.assigned_to_user_id = ? AND boxes.status = ? AND ("
    conditions << user.id.to_s
    conditions << Box::IN_STORAGE_STATUS
    
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
  
  def remove_default(photo)
    if default_customer_photo == photo
      self.default_customer_photo = nil
    elsif default_admin_photo == photo
      self.default_admin_photo = nil
    end
    save
  end
  
  def set_default(photo)
    remove_default(photo)
    if photo.visibility == StoredItemPhoto::CUSTOMER_VISIBILITY
      self.default_customer_photo = photo
    else
      self.default_admin_photo = photo
    end
    save
  end
end
