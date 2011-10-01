# == Schema Information
# Schema version: 20110930213450
#
# Table name: storage_charge_processing_records
#
#  id                   :integer         not null, primary key
#  generated_by_user_id :integer
#  as_of_date           :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

class StorageChargeProcessingRecord < ActiveRecord::Base
  belongs_to :generated_by, :class_name => "User", :foreign_key => :generated_by_user_id
  has_many :storage_charges
end
