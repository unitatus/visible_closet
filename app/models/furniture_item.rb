# == Schema Information
# Schema version: 20120116141356
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
#  creator_id                            :integer
#  user_id                               :integer
#  default_customer_stored_item_photo_id :integer
#  default_admin_stored_item_photo_id    :integer
#

class FurnitureItem < StoredItem
  include HasChargeableUnitProperties
  
  belongs_to :creator, :class_name => "User"
  belongs_to :user
  
  attr_accessible :comma_delimited_tags, :height, :width, :length, :location, :description 
  
  validates_presence_of :height, :message => "can't be blank"
  validates_numericality_of :height, :message => "must be a number", :unless => Proc.new { |furniture_item| furniture_item.height.nil? }
  validates_presence_of :width, :message => "can't be blank"
  validates_numericality_of :width, :message => "must be a number", :unless => Proc.new { |furniture_item| furniture_item.width.nil? }
  validates_presence_of :length, :message => "can't be blank"
  validates_numericality_of :length, :message => "must be a number", :unless => Proc.new { |furniture_item| furniture_item.length.nil? }
  validates_presence_of :creator_id, :message => "must have creator"
  validates_presence_of :user_id, :message => "must be assigned to a user"
  validates_presence_of :description, :message => "can't be blank"
  
  before_destroy :destroy_certain_relationships
  
  INCOMPLETE_STATUS = :incomplete
  RETRIEVAL_REQUESTED = :retrieval_requested
  
  def FurnitureItem.new(attrs=nil)
    furniture_item = super(attrs)
    furniture_item.status = INCOMPLETE_STATUS
    furniture_item
  end
  
  def publish
    update_attribute(:status, StoredItem::IN_STORAGE_STATUS)
    self.charging_start_date = Date.today and save
    if subscriptions.last
      subscriptions.last.start_subscription
    end
  end
  
  def unpublish
    self.status = FurnitureItem::INCOMPLETE_STATUS
    self.charging_start_date = nil
    self.charging_end_date = nil
    return true
  end
  
  def unpublish!
    self.unpublish
    self.save
  end
  
  def add_subscription(duration)
    subscription = subscriptions.create!(:duration_in_months => duration, :user_id => user_id)
    subscription.start_subscription
    return subscription
  end
  
  def incomplete?
    status == INCOMPLETE_STATUS
  end
  
  def comma_delimited_tags
    tags_array = stored_item_tags.collect{|tag| tag.tag }
    tags_array.join(",")
  end
  
  def comma_delimited_tags=(tags)
    tags_array = tags.split(",")
    stored_item_tags.destroy_all
    
    tags_array.each do |tag|
      stored_item_tags.build(:tag => tag)
    end
  end
  
  def published?
    !incomplete?
  end
  
  def stored_item_photo
    the_photo = super
    
    if the_photo.nil?
      return StoredItemPhoto.find(Rails.application.config.furniture_stock_photo_id)
    else
      return the_photo
    end
  end
  
  def FurnitureItem.find_by_id_and_user_id(stored_item_id, user_id)
    find_by_user_id_and_id(user_id, stored_item_id)
  end
  
  def request_retrieval
    update_attribute(:status, RETRIEVAL_REQUESTED)
    AdminMailer.deliver_retrieval_requested(self)
  end
  
  def cancel_service_request
    update_attribute(:status, IN_STORAGE_STATUS)
    AdminMailer.deliver_retrieval_cancelled(self)
  end
  
  def FurnitureItem.tags_search(tags, user)
    conditions = Array.new
    conditions[0] = "user_id = ? AND status != ? AND type = 'FurnitureItem' AND ("
    conditions << user.id.to_s
    conditions << INCOMPLETE_STATUS
    
    tags.each_with_index do |tag, index|
      if (index > 0)
        conditions[0] += " or "
      end
      conditions[0] += "UPPER(tag) like UPPER(?)"
      conditions << "%" + tag + "%"
    end
    
    conditions[0] += ")"
    
    matching_tags = StoredItemTag.joins("INNER JOIN stored_items ON stored_item_tags.stored_item_id = stored_items.id " \
      + "WHERE " + sanitize_sql_array(conditions))
  end
  
  def service_status?
    super || status == RETRIEVAL_REQUESTED
  end
  
  def FurnitureItem.calculate_charges_for_user_furniture_set(user, start_date, end_date, save=false)
    furniture_items = user.furniture_items
    furniture_product = Product.find(Rails.application.config.furniture_storage_product_id)

    furniture_charges = Hash[*furniture_items.collect { |furniture_item| [furniture_item, Rational(0)] }.flatten]
    furniture_events = Hash[*furniture_items.collect { |furniture_item| [furniture_item, []]}.flatten(1) ]
    furniture_items.each do |furniture_item|
      start_date.upto(end_date) do |day|
        if day != start_date
          if furniture_item.in_storage_on(day) && !furniture_item.in_storage_on(day - 1) && !furniture_item.charged_already_on(day)
            furniture_events[furniture_item] << "storage started on " + day.strftime("%m/%d/%Y")
          end
        end
          
        if day != end_date
          if furniture_item.in_storage_on(day) && !furniture_item.in_storage_on(day + 1) && !furniture_item.charged_already_on(day)
            furniture_events[furniture_item] << "storage ended on " + day.strftime("%m/%d/%Y")
          end
        end

        if furniture_item.in_storage_on(day) && !furniture_item.charged_already_on(day)
          furniture_charges[furniture_item] += Rational(furniture_product.price*furniture_item.cubic_feet, Date.days_in_month(day.month, day.year))
        end
      end
    end

    furniture_items.select { |furniture_item| furniture_charges[furniture_item] > 0.0 }.collect { |furniture_item|
      comments = "Storage charges for furniture item ##{furniture_item.id}"
      if furniture_item.description
        desc_to_add = furniture_item.description.length > 10 ? furniture_item.description[0..10] + "..." : furniture_item.description
        comments += " ('#{desc_to_add}')"
      end
      if !furniture_events[furniture_item].empty?
        comments += (" (prorated for " + furniture_events[furniture_item].join(", ") + ")")
      end
      
      # This is a bit asinine. If we were to build the charge on the furniture item's user object, then any other references to user won't get the update until we save.
      # Thus, in the case where we want to calculate the charges for a customer without saving them, we must pass in that customer's object (user) and associate
      # the charges with that object here. Thus, if we said user.charges we'd get this charge, but if said user.furniture_items[0].charges we would not! Bizarre.
      new_charge = user.charges.build(:comments => comments)
      new_charge.total_in_cents = (furniture_charges[furniture_item].to_f*100.0).round
            
      new_charge.associate_with(furniture_item, start_date, end_date)
      
      if (save)
        new_charge.save
        furniture_item.save
      end
      
      new_charge
    }
  end
  
  private 
  
  def destroy_certain_relationships
    subscriptions.each do |subscription|
      subscription.destroy
    end
  end
end
