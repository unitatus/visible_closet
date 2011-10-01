# == Schema Information
# Schema version: 20110930213450
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
  
  belongs_to :payment_profile
  belongs_to :storage_payment_processing_record
  belongs_to :user
  has_many :charges_paid, :class_name => 'Charge'
  
  symbolize :status

  def response=(response)
    self.success = response.success?
    self.authorization = response.authorization
    self.message = response.message
    self.params = response.params
  rescue ActiveMerchant::ActiveMerchantError => e
    self.success = false
    self.authorization = nil
    self.message = e.message
    self.params = {}
  end
  
  def success?
    self.status == SUCCESS_STATUS
  end
  
  def PaymentTransaction.pay(amount, payment_profile, order_id)
    if payment_profile.user.test_user?
      action_msg = "FAKE PURCHASE for testing; did not call active_merchant interface"
      new_payment = create!(:action => action_msg, :amount => amount, :order_id => order_id, :payment_profile_id => payment_profile.id, :user_id => payment_profile.user_id)
      return [new_payment, nil]
    end
    
    response = CIM_GATEWAY.create_customer_profile_transaction({:transaction => {:type => :auth_capture,
                                                                  :amount => amount,
                                                                  :customer_profile_id => payment_profile.user.cim_id,
                                                                  :customer_payment_profile_id => payment_profile.identifier}})

    if response.success?
      new_payment = create!(:action => "purchase", :amount => amount, :response => response, :order_id => order_id, :payment_profile_id => payment_profile.id, :user_id => payment_profile.user_id)
      return [new_payment, nil]
    elsif RAILS_ENV == "development"
      new_payment = create!(:action => "purchase in dev (failed, overrode)", :amount => amount, :response => response, :order_id => order_id, :payment_profile_id => payment_profile.id, :user_id => payment_profile.user_id)
      return [new_payment, nil]
    else
      [nil, response.message]
    end
  end
end
