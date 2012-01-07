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

class FurnitureItem < StoredItem
  belongs_to :creator, :class_name => "User"
  belongs_to :user
  has_and_belongs_to_many :subscriptions
  
  attr_accessible :height, :width, :length, :location, :comma_delimited_tags
  
  validates_presence_of :height, :message => "can't be blank"
  validates_numericality_of :height, :message => "must be a number", :unless => Proc.new { |furniture_item| furniture_item.height.nil? }
  validates_presence_of :width, :message => "can't be blank"
  validates_numericality_of :width, :message => "must be a number", :unless => Proc.new { |furniture_item| furniture_item.width.nil? }
  validates_presence_of :length, :message => "can't be blank"
  validates_numericality_of :length, :message => "must be a number", :unless => Proc.new { |furniture_item| furniture_item.length.nil? }
  validates_presence_of :location, :message => "can't be blank"
  validates_presence_of :creator_id, :message => "must have creator"
  validates_presence_of :user_id, :message => "must be assigned to a user"
  
  before_destroy :destroy_certain_relationships
  
  INCOMPLETE_STATUS = :incomplete
  
  def FurnitureItem.new(attrs=nil)
    furniture_item = super(attrs)
    furniture_item.status = INCOMPLETE_STATUS
    furniture_item
  end
  
  def current_subscription
    subscription_on(Date.today)
  end
  
  def subscription_on(date)
    subscriptions.select { |subscription| subscription.applies_on(date) }.last
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
      StoredItemTag.create!(:stored_item_id => self.id, :tag => tag)
    end
  end
  
  def cubic_feet
    if self.length.nil? || self.width.nil? || self.height.nil?
      return nil
    else
      divisor = Rails.application.config.box_dimension_divisor
      return (self.length/divisor) * (self.width/divisor) * (self.height/divisor)
    end
  end
  
  private 
  
  def destroy_certain_relationships
    subscriptions.each do |subscription|
      subscription.destroy
    end
  end
end
