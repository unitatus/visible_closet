# == Schema Information
# Schema version: 20110815030426
#
# Table name: subscriptions
#
#  id                 :integer         not null, primary key
#  start_date         :datetime
#  end_date           :datetime
#  user_id            :integer
#  duration_in_months :integer
#  created_at         :datetime
#  updated_at         :datetime
#

class Subscription < ActiveRecord::Base
  has_many :boxes
  belongs_to :user
end
