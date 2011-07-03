# == Schema Information
# Schema version: 20110703192540
#
# Table name: addresses
#
#  id             :integer         not null, primary key
#  first_name     :string(255)
#  last_name      :string(255)
#  day_phone      :string(255)
#  evening_phone  :string(255)
#  address_line_1 :string(255)
#  address_line_2 :string(255)
#  city           :string(255)
#  state          :string(255)
#  zip            :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  address_name   :string(255)
#  user_id        :integer
#  country        :string(255)
#

class Address < ActiveRecord::Base

  belongs_to :user

  validates_presence_of :first_name, :message => "First name cannot be blank"
  validates_presence_of :last_name, :message => "Last name cannot be blank"
  validates_presence_of :day_phone, :message => "Day phone cannot be blank"
  validates_presence_of :address_line_1, :message => "Address line 1 cannot be blank"
  validates_presence_of :city, :message => "City cannot be blank"
  validates_presence_of :state, :message => "State must be selected"
  validates_presence_of :zip, :message => "Zip code cannot be blank"

  validates_length_of :day_phone, :minimum => 10, :maximum => 10, :message => "Please enter a 10-digit phone number", :unless => :skip_day_content_validation
  validates_numericality_of :day_phone, :message => "Please enter only numbers for the phone", :unless => :skip_day_content_validation
  validates_length_of :evening_phone, :minimum => 10, :maximum => 10, :message => "Please enter a 10-digit phone number", :unless => :skip_evening_content_validation
  validates_numericality_of :evening_phone, :message => "Please enter only numbers for the phone", :unless => :skip_evening_content_validation

  def skip_day_content_validation
    day_phone.empty?
  end

  def skip_evening_content_validation
    evening_phone.empty?
  end

  # Hard coded country for now
  def new
    country = "US"
    super
  end
end
