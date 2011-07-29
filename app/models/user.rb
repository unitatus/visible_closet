# == Schema Information
# Schema version: 20110729131208
#
# Table name: users
#
#  id                         :integer         not null, primary key
#  email                      :string(255)     default(""), not null
#  encrypted_password         :string(128)     default(""), not null
#  reset_password_token       :string(255)
#  remember_created_at        :datetime
#  sign_in_count              :integer         default(0)
#  current_sign_in_at         :datetime
#  last_sign_in_at            :datetime
#  current_sign_in_ip         :string(255)
#  last_sign_in_ip            :string(255)
#  password_salt              :string(255)
#  confirmation_token         :string(255)
#  confirmed_at               :datetime
#  confirmation_sent_at       :datetime
#  failed_attempts            :integer         default(0)
#  unlock_token               :string(255)
#  locked_at                  :datetime
#  authentication_token       :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#  last_name                  :string(255)
#  first_name                 :string(255)
#  beta_user                  :boolean         default(TRUE)
#  signup_comments            :text
#  role                       :string(255)
#  cim_id                     :string(255)
#  default_payment_profile_id :integer
#

class User < ActiveRecord::Base
  # Roles
  ADMIN = :admin
  MANAGER = :manager
  NORMAL = :normal

  # Other devise modules are:
  # :token_authenticatable, :encryptable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, :lockable, :timeoutable, :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, 
                  :password, # not stored in DB
                  :password_confirmation, # not stored in DB
                  :remember_me, 
                  :beta_user,
                  :first_name,
                  :last_name,
                  :signup_comments,
                  :role

  symbolize :role

  has_many :boxes
  has_many :payment_profiles
  has_many :addresses

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates_inclusion_of :role, :in => [ ADMIN, MANAGER, NORMAL ]

  has_many :addresses
    
  def after_initialize 
    self.role ||= NORMAL
  end
  
  def cim_id
    if read_attribute(:cim_id)
      return read_attribute(:cim_id)
    end
    
    if self.id.nil? || self.email.nil? || self.first_name.nil?
      raise "Cannot get cim_id without saving user object."
    end
    
    cim_user = {:profile => cim_user_profile}
    
    response = CIM_GATEWAY.create_customer_profile(cim_user)
    
    if response.success? and response.authorization
      update_attribute(:cim_id, response.authorization)
      response.authorization
    else
      raise "Failed to generate cim_id with response " << response.inspect
    end
  end
  
  # This method automatically saves changes to this field to the database
  def cim_id=(value)
    if self.id.nil? || self.email.nil? || self.first_name.nil?
      raise "Cannot set cim_id without saving user object."
    end

    if read_attribute(:cim_id).nil?
      write_attribute(:cim_id, value)
    elsif value.nil?
      delete_cim_profile
      write_attribute(:cim_id, value)
      User.update_all("cim_id=null")
    else
      raise "Cannot set cim_id - this can only be done via connection with ActiveMerchant"
    end
  end
  
  def email=(value)
    write_attribute(:email, value)

    if !self.id.nil?
      update_cim_profile
    end    
  end
  
  def first_name=(value)
    write_attribute(:first_name, value)
    if !self.id.nil?
      update_cim_profile
    end    
  end
  
  def last_name=(value)
    write_attribute(:last_name, value)
    if !self.id.nil?
      update_cim_profile
    end    
  end

  def destroy
    if delete_cim_profile and super
      return true
    end
    return false
  end
  
  private 

  def delete_cim_profile
    if not self.cim_id
      return false
    end
    
    response = CIM_GATEWAY.delete_customer_profile(:customer_profile_id => self.cim_id)

    if response.success?
      return true
    end
    return false
  end
  
  def update_cim_profile
    if not self.cim_id
      return false
    end
    
    response = CIM_GATEWAY.update_customer_profile(:profile => cim_user_profile.merge({
        :customer_profile_id => self.cim_id}))

    if response.success?
      return true
    end
    return false
  end
  
  def cim_user_profile
    return {:merchant_customer_id => self.id, :email => self.email, :description => self.first_name + " " + self.last_name}
  end
end
