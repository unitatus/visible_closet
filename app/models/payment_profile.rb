# == Schema Information
# Schema version: 20110701051132
#
# Table name: payment_profiles
#
#  id               :integer         not null, primary key
#  identifier       :string(255)
#  last_four_digits :string(255)
#  user_id          :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class PaymentProfile < ActiveRecord::Base
end
