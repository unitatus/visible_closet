# == Schema Information
# Schema version: 20111210184710
#
# Table name: payment_transactions
#
#  id                                   :integer         not null, primary key
#  order_id                             :integer
#  action                               :string(255)
#  amount                               :float
#  authorization                        :string(255)
#  message                              :string(255)
#  params                               :text
#  user_id                              :integer
#  created_at                           :datetime
#  updated_at                           :datetime
#  payment_profile_id                   :integer
#  status                               :string(255)
#  storage_payment_processing_record_id :integer
#  auth_transaction_id                  :string(255)
#

#
# Conceptually, a payment transaction can be associated with an order (to pay for the whole order) or with nothing (indicating simply a payment on the user's account).
# Really, the order reference is a convenience method -- the order can be gotten via charges, an really only applies to orders that the user explicitly created.
# Typically a payment is simple to pay for a series of charges, which could be for a variety of things, including orders that the user did not explicitly create
# (for instance, inventorying orders, which are created by administrators when a box is marked for inventorying).
class PaymentTransaction < ActiveRecord::Base
  serialize :params
  
  SUCCESS_STATUS = :success
  FAILURE_STATUS = :failure
  RECTIFY_STATUS = :rectify
  
  REQUIRES_SETTLEMENT_MSG = "The referenced transaction does not meet the criteria for issuing a credit."
  
  belongs_to :payment_profile
  belongs_to :storage_payment_processing_record
  belongs_to :user
  has_many :charges_paid, :class_name => 'Charge'
  
  symbolize :status

  def response=(response)
    self.authorization = response.authorization
    self.message = response.message
    self.params = response.params
  rescue ActiveMerchant::ActiveMerchantError => e
    self.authorization = nil
    self.message = e.message
    self.params = {}
  end
  
  def success?
    self.status == SUCCESS_STATUS
  end
  
  def rectify?
    self.status == RECTIFY_STATUS
  end
  
  def PaymentTransaction.refund(amount, payment_profile, transaction)
    create_transaction(:refund, amount, payment_profile, nil, transaction.auth_transaction_id)
  end

  def PaymentTransaction.pay(amount, payment_profile, order_id=nil)
    create_transaction(:auth_capture, amount, payment_profile, order_id, nil)
  end
  
  def deletable?
    false
  end
  
  private
  
  def PaymentTransaction.create_transaction(type, amount, payment_profile, order_id=nil, transaction_id=nil)
    amt_to_save = ((type == :refund) ? amount * -1 : amount)
    if payment_profile.user.test_user?
      action_msg = "FAKE PURCHASE for testing; did not call active_merchant interface"
      new_payment = create!(:action => action_msg, :status => SUCCESS_STATUS, :amount => amt_to_save, :order_id => order_id, :payment_profile_id => payment_profile.id, :user_id => payment_profile.user_id)
      return [new_payment, nil]
    end
    
    response = CIM_GATEWAY.create_customer_profile_transaction({:transaction => {:type => type,
                                                                  :amount => amount,
                                                                  :customer_profile_id => payment_profile.user.cim_id,
                                                                  :customer_payment_profile_id => payment_profile.identifier,
                                                                  :trans_id => transaction_id}})

    if response.success?
      new_payment = create!(:action => "purchase", :status => SUCCESS_STATUS, :amount => amt_to_save, :response => response, :order_id => order_id, :payment_profile_id => payment_profile.id, :user_id => payment_profile.user_id, :auth_transaction_id => response.params["direct_response"]["transaction_id"])
      return [new_payment, nil]
    elsif order_id.nil? && type == :auth_capture # this means that it was a storage charge, in which case we need to keep track of the payment for repayment later
      new_payment = create!(:action => "purchase", :status => RECTIFY_STATUS, :amount => amt_to_save, :response => response, :payment_profile_id => payment_profile.id, :user_id => payment_profile.user_id)
      return [new_payment, response.message]
    else # this was an attempt to pay for an order or submit a refund, which we can allow to just die
      [nil, response.message]
    end
  end
end
