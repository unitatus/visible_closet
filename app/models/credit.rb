# == Schema Information
# Schema version: 20111218224103
#
# Table name: credits
#
#  id          :integer         not null, primary key
#  amount      :float
#  user_id     :integer
#  description :string(255)
#

class Credit < ActiveRecord::Base
  has_one :payment_transaction
  belongs_to :user
  
  def deletable?
    payment_transaction.nil?
  end
end
