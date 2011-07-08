# == Schema Information
# Schema version: 20110701051132
#
# Table name: orders
#
#  id                  :integer         not null, primary key
#  cart_id             :integer
#  ip_address          :string(255)
#  user_id             :integer
#  created_at          :datetime
#  updated_at          :datetime
#  billing_address_id  :integer
#  shipping_address_id :integer
#

class Order < ActiveRecord::Base
  belongs_to :cart
  has_many :payment_transactions
  has_many :order_lines, :dependent => :destroy
  has_one :user

  attr_accessor :card_number, :card_verification_value, :card_first_name, :card_last_name, :card_type, :card_month, :card_year
  attr_accessible :user_id, :created_at

  validate :validate_card, :on => :create

  def purchase
    transaction_successful = false

    self.transaction do
      if (!save)
        raise ActiveRecord::Rollback
      end
      # If this gets a DB error an uncaught exception will be thrown, which should kill the transaction
      do_purchase_processing

      # TODO: This needs to be refactored into a payment processor object that takes a user, payment object thingie, and a charges array, so we can 
      # have charges for the user.
      response = PURCHASE_GATEWAY.purchase(total_in_cents, credit_card, purchase_options)
      payment_transactions.create!(:action => "purchase", :amount => total_in_cents, :response => response)
      if !response.success?
        errors.add("cc_response", response.message)
        raise ActiveRecord::Rollback
      end
      
      transaction_successful = true
    end # end transaction    

    return transaction_successful
  end

  def total_in_cents
    (cart.estimated_total*100).round
  end

  def shipping_address
    Address.find(self.shipping_address_id)
  end
  
  def billing_address
    Address.find(self.billing_address_id)
  end
  
  def build_order_line(attributes={})
    order_line = order_lines.build(:attributes => attributes)
    
    order_line.order_id = id
    
    order_line
  end
  
  def status
    status = OrderLine::PROCESSED_STATUS
    
    order_lines.each do |order_line|
      if order_line.status == OrderLine::NEW_STATUS
        status = OrderLine::NEW_STATUS
      end
    end
    
    return status
  end
  
  def generate_charges
    raise "Attempted to call generate charges on unsaved order" unless self.id
    
    order_lines.each do | order_line |
      raise "Failed to generate charge for order_line " + order_line.inspect unless Charge.create!(:user_id => user_id, :total_in_cents => order_line.total_in_cents, :product_id => order_line.product_id)
    end
  end
  
  private

  def purchase_options
    billing_address = Address.find(billing_address_id)
    {
      :ip => ip_address,
      :billing_address => {
        :name => billing_address.first_name + " " + billing_address.last_name,
        :address1 => billing_address.address_line_1,
        :address2 => billing_address.address_line_2,
        :city => billing_address.city,
        :state => billing_address.state,
        :country => billing_address.country,
        :zip => billing_address.zip
      }
    }
  end

  def validate_card
    unless credit_card.valid?
      credit_card.errors.each do |attr, messages|
        messages.each do | message |
          errors.add("card_" + attr, message)
        end
      end
    end
  end

  def credit_card
    @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
      :type => card_type,
      :number => card_number,
      :verification_value => card_verification_value,
      :month => card_month,
      :year => card_year,
      :first_name => card_first_name,
      :last_name => card_last_name
    )
  end
  
  # this method throws a RuntimeError b/c the only way that save wouldn't work is if something went really wrong
  # and we don't want to miss that
  def do_purchase_processing()
    cart.mark_ordered
    
    if (!cart.save)
      raise "Unable to save cart. Cart: " << cart.inspect
    end
    
    user = User.find(cart.user_id)
    
    order_lines.each do |order_line|
      product = order_line.product
      
      if product.id.to_s == Rails.application.config.our_box_insured_product_id.to_s
        insured = true
        type = Box::VC_BOX_TYPE
        status = Box::NEW_STATUS
      elsif product.id.to_s == Rails.application.config.our_box_uninsured_product_id.to_s
        insured = false
        type = Box::VC_BOX_TYPE
        status = Box::NEW_STATUS
      elsif product.id.to_s == Rails.application.config.your_box_insured_product_id.to_s
        insured = true
        type = Box::CUST_BOX_TYPE
        status = Box::BEING_PREPARED_STATUS
        order_line.status = OrderLine::PROCESSED_STATUS
        order_line.save
      elsif product.id.to_s == Rails.application.config.your_box_uninsured_product_id.to_s
        insured = false
        type = Box::CUST_BOX_TYPE
        status = Box::BEING_PREPARED_STATUS
        order_line.status = OrderLine::PROCESSED_STATUS
        order_line.save
      else
        raise "Bad configuration - no match on product " << product.inspect << ", for which product.id returned " << product.id.to_s << "."
      end
      
      for i in 1..(order_line.quantity)
        if !Box.create!(:assigned_to_user_id => user.id, :order_line_id => order_line.id, :status => status, :box_type => type, :insured => insured, :indexing_status => Box::NO_INDEXING_REQUESTED)
          raise "Standard box creation failed."
        end
      end # inner for loop
    end
  end
end
