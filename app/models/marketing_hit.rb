# == Schema Information
# Schema version: 20110812172047
#
# Table name: marketing_hits
#
#  id         :integer         not null, primary key
#  source     :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class MarketingHit < ActiveRecord::Base
end
