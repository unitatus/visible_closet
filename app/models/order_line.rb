# == Schema Information
# Schema version: 20110705224828
#
# Table name: order_lines
#
#  id         :integer         not null, primary key
#  order_id   :integer
#  product_id :integer
#  quantity   :integer
#  status     :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class OrderLine < ActiveRecord::Base
  belongs_to :order
  
  after_initialize :init_status
  
  def init_status
    if status.blank?
      self.status = "new"
    end
  end
end
