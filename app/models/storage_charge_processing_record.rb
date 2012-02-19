# == Schema Information
# Schema version: 20111001143818
#
# Table name: storage_charge_processing_records
#
#  id                   :integer         not null, primary key
#  generated_by_user_id :integer
#  as_of_date           :datetime
#  created_at           :datetime
#  updated_at           :datetime
#  locked_for_editing   :boolean
#

class StorageChargeProcessingRecord < ActiveRecord::Base
  belongs_to :generated_by, :class_name => "User", :foreign_key => :generated_by_user_id
  has_many :storage_charges # can't use dependent destroy, because need to kill the charge
  has_many :credits, :dependent => :destroy
  before_destroy :delete_storage_charges
  
  def delete_storage_charges
    storage_charges.each do |storage_charge|
      storage_charge.charge.destroy # will also kill storage_charge
    end
  end
end
