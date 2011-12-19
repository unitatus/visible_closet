# == Schema Information
# Schema version: 20111219003126
#
# Table name: credits
#
#  id                  :integer         not null, primary key
#  amount              :float
#  user_id             :integer
#  created_at          :datetime
#  updated_at          :datetime
#  description         :string(255)
#  created_by_admin_id :integer
#

class Credit < ActiveRecord::Base
  has_one :payment_transaction
  belongs_to :user
  belongs_to :created_by_admin, :class_name => "User"
  
  def deletable?
    payment_transaction.nil?
  end
end
