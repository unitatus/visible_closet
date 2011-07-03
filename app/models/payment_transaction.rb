# == Schema Information
# Schema version: 20110701051132
#
# Table name: payment_transactions
#
#  id            :integer         not null, primary key
#  order_id      :integer
#  action        :string(255)
#  amount        :integer
#  success       :boolean
#  authorization :string(255)
#  message       :string(255)
#  params        :text
#  user_id       :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class PaymentTransaction < ActiveRecord::Base
  serialize :params

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
end
