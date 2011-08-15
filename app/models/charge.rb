# == Schema Information
# Schema version: 20110815195751
#
# Table name: charges
#
#  id             :integer         not null, primary key
#  user_id        :integer
#  total_in_cents :integer
#  product_id     :integer
#  created_at     :datetime
#  updated_at     :datetime
#  order_id       :integer
#

# Conceptually, a charge can be related to: and order line; a box in storage.
class Charge < ActiveRecord::Base
end
