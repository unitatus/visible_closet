# == Schema Information
# Schema version: 20110801025140
#
# Table name: interested_people
#
#  id         :integer         not null, primary key
#  email      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class InterestedPerson < ActiveRecord::Base
end
