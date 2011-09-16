# == Schema Information
# Schema version: 20110803210001
#
# Table name: users
#
#  id                          :integer         not null, primary key
#  email                       :string(255)     default(""), not null
#  encrypted_password          :string(128)     default(""), not null
#  reset_password_token        :string(255)
#  remember_created_at         :datetime
#  sign_in_count               :integer         default(0)
#  current_sign_in_at          :datetime
#  last_sign_in_at             :datetime
#  current_sign_in_ip          :string(255)
#  last_sign_in_ip             :string(255)
#  password_salt               :string(255)
#  confirmation_token          :string(255)
#  confirmed_at                :datetime
#  confirmation_sent_at        :datetime
#  failed_attempts             :integer         default(0)
#  unlock_token                :string(255)
#  locked_at                   :datetime
#  authentication_token        :string(255)
#  created_at                  :datetime
#  updated_at                  :datetime
#  last_name                   :string(255)
#  first_name                  :string(255)
#  beta_user                   :boolean         default(TRUE)
#  signup_comments             :text
#  role                        :string(255)
#  cim_id                      :string(255)
#  default_payment_profile_id  :integer
#  default_shipping_address_id :integer
#

class User < ActiveRecord::Base
  # Roles
  ADMIN = :admin
  MANAGER = :manager
  NORMAL = :normal

  # Other devise modules are:
  # :token_authenticatable, :encryptable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable, :lockable, :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, 
                  :password, # not stored in DB
                  :password_confirmation, # not stored in DB
                  :remember_me, 
                  :beta_user,
                  :first_name,
                  :last_name,
                  :signup_comments,
                  :role,
                  :default_shipping_address_attributes,
                  :default_payment_profile_attributes

  symbolize :role

  has_many :boxes, :foreign_key => :assigned_to_user_id, :dependent => :destroy
  has_many :payment_profiles, :dependent => :destroy
  has_many :addresses, :dependent => :destroy
  has_many :orders, :dependent => :destroy
  has_many :carts, :dependent => :destroy
  has_many :charges, :dependent => :destroy
  has_many :payment_transactions, :dependent => :destroy
  has_many :subscriptions, :dependent => :destroy
  has_and_belongs_to_many :rental_agreement_versions

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates_inclusion_of :role, :in => [ ADMIN, MANAGER, NORMAL ]

  belongs_to :default_shipping_address, :class_name => "Address"
  accepts_nested_attributes_for :default_shipping_address, :allow_destroy => true
  belongs_to :default_payment_profile, :class_name => "PaymentProfile"
  accepts_nested_attributes_for :default_payment_profile, :allow_destroy => true
  
  def after_initialize 
    self.role ||= NORMAL
  end
  
  def cart
    Cart.find_active_by_user_id(self.id)
  end
  
  def get_or_create_cart
    return_cart = self.cart
    if return_cart.nil?
      return_cart = Cart.new
      return_cart.user = self
    end
    
    return_cart
  end
  
  def addresses
    Address.find_active(self.id, :order => :first_name)
  end
  
  # This is to avoid a rather interesting bug. If we call this right after create the cim id will be saved. If we wait, then it's possible that
  # cim_id will get called for the first time when doing another action as part of a transaction. If this happens, then the rollback will delete the
  # cim_id from the database, but will not delete it from authorize.net, and the next time we try to set the cim_id we will be "setting it for the first time"
  # from our perspective, but authorize.net will see that an id already exists and will throw an error. This can happen especially if there is a failure of
  # some sort on payment_profile create, since that is generally the first time that cim_id is called in the normal flow.
  def after_create
    self.cim_id
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
  
  def transaction_history
    unsorted_transactions = GenericTransaction.find_all_by_user_id(self.id)
    
    unsorted_transactions.sort {|x,y| x.created_at <=> y.created_at }
  end

  def destroy
    # since we are deleting, we don't really care if we get a cim error; it's most likely because we had a failure in the past and the
    # cim_id was deleted in authorize.net
    delete_cim_profile
    super
  end
  
  def active_address_count
    Address.count(:conditions => "status = 'active' AND user_id = #{self.id}")
  end
  
  def payment_profile_count
    PaymentProfile.count(:conditions => "user_id = #{self.id}")
  end
  
  def box_count
    Box.count(:conditions => "assigned_to_user_id = #{self.id}")
  end
  
  def boxes_in_storage
    all_boxes = self.boxes
    all_boxes.select { |box| box.status == Box::IN_STORAGE_STATUS }
  end
  
  def order_count
    Order.count(:conditions => "user_id = #{self.id}")
  end
    
  def last_box_num
    if box_count == 0
      nil
    else
      Box.where(:assigned_to_user_id => self.id).maximum("box_num")
    end
  end
  
  def next_box_num
    last_num = last_box_num
    if (last_num.nil?)
      1
    else last_num + 1
    end
  end
  
  def admin?
    return self.role == ADMIN
  end
  
  def manager?
    return self.role == ADMIN || self.role == MANAGER
  end
  
  def shipments
    Shipment.find_all_by_user_id(id, :order => "created_at DESC")
  end
  
  def clear_test_data
    orders.each do |order|
      order.destroy
    end
    
    carts.each do |cart|
      cart.destroy
    end
    
    charges.each do |charge|
      charge.destroy
    end
    
    payment_profiles.each do |profile|
      if profile != default_payment_profile
        profile.destroy
      end
    end
    
    addresses.each do |address|
      if address != default_shipping_address
        address.destroy
      end
    end
    
    payment_transactions.each do |transaction|
      transaction.destroy
    end
    
    subscriptions.each do |subscription|
      subscription.destroy
    end
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
