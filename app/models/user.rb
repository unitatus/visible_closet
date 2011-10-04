# == Schema Information
# Schema version: 20110930133517
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
#  test_user                   :boolean
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
  has_many :storage_charge_processing_records, :dependent => :destroy
  has_many :storage_payment_processing_records, :dependent => :destroy
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
  
  def has_cart_items?
    if cart.nil? || cart.items.empty?
      return false
    else
      return true
    end
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
  
  def has_cart_items?
    if cart.nil? || cart.cart_items.empty?
      return false
    else
      return true
    end
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
    
    # can't sort this in the database because transaction can be a charge or a payment, and it's a royal pain to do a merge like that in the database with rails
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
  
  def box_count(type=nil)
    if @box_counts.nil?
      @box_counts = Hash.new
    end
    
    conditions = "assigned_to_user_id = #{self.id} AND status != '#{Box::INACTIVE_STATUS.to_s}' AND box_type = "
    
    if @box_counts[Box::CUST_BOX_TYPE].nil?
      @box_counts[Box::CUST_BOX_TYPE] = Box.count(:conditions => conditions + "'" + Box::CUST_BOX_TYPE.to_s + "'")
    end
    
    if @box_counts[Box::VC_BOX_TYPE].nil?
      @box_counts[Box::VC_BOX_TYPE] = Box.count(:conditions => conditions + "'" + Box::VC_BOX_TYPE.to_s + "'")
    end
    
    if type.nil?
      @box_counts[Box::VC_BOX_TYPE] + @box_counts[Box::CUST_BOX_TYPE]
    else
      @box_counts[type]
    end
  end
  
  def pay_off_account_balance_and_save
    payment = nil
    self.transaction do
      # Credit card might be fixed; let's turn those old rectify payments into failed payments
      rectify_payments.each do |rectify_payment|
        rectify_payment.update_attribute(:status, PaymentTransaction::FAILURE_STATUS)
      end

      balance_to_pay = current_account_balance * -1 # current account balance negative means user owes us money
    
      if balance_to_pay > 0.0
        payment, message = PaymentTransaction.pay(balance_to_pay, default_payment_profile)
        if payment.success?
          UserMailer.deliver_storage_charges_paid(self, payment)
        else
          UserMailer.deliver_storage_charge_cc_rejected(self, message)
        end
      end
    
      save
    end
    
    return payment
  end
  
  def has_stored_items?
    stored_item_count > 0
  end
  
  def stored_item_count
    StoredItem.joins(:box).count(:conditions => "assigned_to_user_id = #{self.id}")
  end
  
  # this only tests customer boxes; vc box cubic feet are always the same size
  def stored_cubic_feet_count
    matching_boxes = boxes.select { |box| box.box_type == Box::CUST_BOX_TYPE && box.status = Box::IN_STORAGE_STATUS }
    total_cubic_feet = 0.0
    matching_boxes.each do |box|
      total_cubic_feet += (box.cubic_feet.nil? ? 0.0 : box.cubic_feet)
    end
    
    return total_cubic_feet
  end
  
  def stored_box_count(type=nil)
    if @stored_box_counts.nil?
      @stored_box_counts = Hash.new
    end
    
    conditions = "assigned_to_user_id = #{self.id} AND status = '#{Box::IN_STORAGE_STATUS.to_s}' AND box_type = "
    
    if @stored_box_counts[Box::CUST_BOX_TYPE].nil?
      @stored_box_counts[Box::CUST_BOX_TYPE] = Box.count(:conditions => conditions + "'" + Box::CUST_BOX_TYPE.to_s + "'")
    end
    
    if @stored_box_counts[Box::VC_BOX_TYPE].nil?
      @stored_box_counts[Box::VC_BOX_TYPE] = Box.count(:conditions => conditions + "'" + Box::VC_BOX_TYPE.to_s + "'")
    end
    
    if type.nil?
      @stored_box_counts[Box::VC_BOX_TYPE] + @stored_box_counts[Box::CUST_BOX_TYPE]
    else
      @stored_box_counts[type]
    end
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
  
  def has_rectify_payments?
    payment_transactions.each do |payment_transaction|
      if payment_transaction.rectify?
        return true
      end
    end
    
    return false
  end
  
  def rectify_payments
    payment_transactions.select {|payment| payment.rectify? }
  end
  
  def resolve_rectify_payments
    self.transaction do
      rectify_payment_transactions.each do |rectify_payment|
        # A rectify payment signifies that "this needs to be taken care of". By "failing" old rectify payments and re-attempting, we 
        # keep a record of the failed payments while either getting new, "good" payments of replacing them with new "rectify" payments.
        new_payment, message = PaymentTransaction.pay(rectify_payment.amount, default_payment_profile)
        payment_transactions << new_payment
        rectify_payment.update_attribute(:status, PaymentTransaction::FAILURE_STATUS)
        # want the rectify payment to show up in the list of associated storage processing records
        if rectify_payment.storage_payment_processing_record
          rectify_payment.storage_payment_processing_record.payment_transactions << new_payment
        end
        save # save all those new payment relationships
        
        if !new_payment.success?
          return false
        else
          UserMailer.deliver_storage_charges_paid(self, new_payment)
        end
      end
    end # end transaction
    
    return true
  end
  
  def last_successful_payment_transaction
    successful_payment_transactions.last
  end
  
  def active_payment_profiles
    payment_profiles.select {|profile| profile.active? }
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

  def current_account_balance(include_news=false)
    account_balance_as_of(Date.today, include_news)
  end
  
  def current_account_balance_ignore_rectify(include_news=false)
    account_balance_as_of(Date.today, include_news, false)
  end
  
  # Note: the "to_date" calls are to ensure that we aren't comparing times -- just dates (since the database can't handle straight dates)
  def account_balance_as_of(date, include_news=false, include_rectify=true)
    running_total = 0.0

    charges.each do |charge|
      if (charge.created_at && charge.created_at.to_date <= date.to_date) || (include_news && charge.created_at.nil?)
        running_total = running_total - charge.amount
      end
    end
    
    payments = include_rectify ? non_failed_payment_transactions : successful_payment_transactions
    payments.each do |payment_transaction|
      running_total = running_total + payment_transaction.amount.to_f if payment_transaction.created_at.to_date <= date.to_date
    end

    return running_total.round(2) # takes care of obnoxious adding errors
  end
  
  def payments_during_month(date=nil)
    if date.nil?
      date = Date.today
    end
    
    payments_between(DateHelper.start_of_month(date), DateHelper.end_of_month(date))
  end
  
  def payments_between(start_date, end_date)
    non_failed_payment_transactions.select {|payment| payment.created_at >= start_date && payment.created_at <= end_date }
  end
  
  def charges_during_month(date=nil)
    if date.nil?
      date = Date.today
    end
    
    charges_between(DateHelper.start_of_month(date), DateHelper.end_of_month(date))
  end
  
  def charges_between(start_date, end_date)
    charges.select {|charge| charge.created_at.nil? ? false : charge.created_at >= start_date && charge.created_at <= end_date }
  end
  
  def calculate_subscription_charges(as_of_date = self.end_of_month, force=false, save=false)
    if !@recently_calculated_anticipated || force
      last_charged_date = self.earliest_effective_charge_date
      if last_charged_date && last_charged_date > DateHelper.start_of_month(as_of_date)
        last_charged_date = DateHelper.start_of_month(as_of_date)
      end
      return_charges = Box.calculate_charges_for_user_box_set(self, last_charged_date.nil? ? nil : last_charged_date.to_date+1, as_of_date, save)
      @recently_calculated_anticipated = true
      return_charges
    else
      anticipated_charges
    end
  end
  
  def anticipated_charges
    if @recently_calculated_anticipated
      charges.select {|charge| charge.id.nil? }
    else
      calculate_subscription_charges
    end
  end
  
  def will_have_charges_at_end_of_month?
    boxes.each do |box|
      if box.chargable?
        return true
      end
    end
    
    return account_balance_as_of(DateHelper.end_of_month) < 0
  end
  
  def non_failed_payment_transactions
    payment_transactions.select {|payment_transaction| payment_transaction.status != PaymentTransaction::FAILURE_STATUS }
  end
  
  def rectify_payment_transactions
    payment_transactions.select {|payment_transaction| payment_transaction.status == PaymentTransaction::RECTIFY_STATUS }
  end
  
  def successful_payment_transactions
    payment_transactions.select {|payment_transaction| payment_transaction.success? }
  end
  
  # This needs to account for boxes that don't have charges yet but need to be included. If any box has been received but never charged, return the receive date.
  # If any received box's charge end date is nil, return the receive date. Otherwise, return the earliest actual charge date. 
  def earliest_effective_charge_date
    the_earliest_effective_charge_date = nil
    
    self.boxes.each do |box|
      if box.chargable?
        the_earliest_effective_charge_date ||= box.latest_charge_end_date
        if the_earliest_effective_charge_date && the_earliest_effective_charge_date > box.latest_charge_end_date
          the_earliest_effective_charge_date = box.latest_charge_end_date
        end
      end
    end
    
    return the_earliest_effective_charge_date
  end
  
  def next_charge_date
    end_of_month
  end
    
  def end_of_month(date = nil)
    if date.nil?
      date = Date.today
    end
    
    Date.parse((date.month == 12 ? date.year + 1 : date.year).to_s + "-" + (date.month == 12 ? 1 : date.month + 1).to_s + "-01") - 1
  end
  
  def not_test_user?
    !test_user?
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
