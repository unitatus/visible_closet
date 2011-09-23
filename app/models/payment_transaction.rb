# == Schema Information
# Schema version: 20110819212810
#
# Table name: payment_transactions
#
#  id                 :integer         not null, primary key
#  order_id           :integer
#  action             :string(255)
#  amount             :float
#  success            :boolean
#  authorization      :string(255)
#  message            :string(255)
#  params             :text
#  user_id            :integer
#  created_at         :datetime
#  updated_at         :datetime
#  payment_profile_id :integer
#

class PaymentTransaction < ActiveRecord::Base
  serialize :params
  
  belongs_to :payment_profile
  has_many :charges_paid, :class_name => 'Charge'

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
  
  def PaymentTransaction.pay(charges, payment_profile, order_id)
    total_to_pay = 0.0
    
    charges.each do |charge|
      total_to_pay += (charge.total_in_cents / 100.0)
    end
    
    response = CIM_GATEWAY.create_customer_profile_transaction({:transaction => {:type => :auth_capture,
                                                                  :amount => total_to_pay,
                                                                  :customer_profile_id => payment_profile.user.cim_id,
                                                                  :customer_payment_profile_id => payment_profile.identifier}})

    if response.success?
      new_payment = create!(:action => "purchase", :amount => total_to_pay, :response => response, :order_id => order_id, :payment_profile_id => payment_profile.id, :user_id => payment_profile.user_id)
      charges.each do |charge|
        charge.update_attribute(:payment_transaction_id, new_payment.id)
      end
      return [new_payment, nil]
    elsif RAILS_ENV == "development"
      new_payment = create!(:action => "purchase in dev (failed, overrode)", :amount => total_to_pay, :response => response, :order_id => order_id, :payment_profile_id => payment_profile.id, :user_id => payment_profile.user_id)
      charges.each do |charge|
        charge.update_attribute(:payment_transaction_id, new_payment.id)
      end
      return [new_payment, nil]
    else
      [nil, response.message]
    end
  end
end
