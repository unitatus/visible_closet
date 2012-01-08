# == Schema Information
# Schema version: 20120108204741
#
# Table name: chargeable_unit_properties
#
#  id                   :integer         not null, primary key
#  height               :float
#  width                :float
#  length               :float
#  location             :string(255)
#  chargeable_unit_id   :integer
#  chargeable_unit_type :string(255)
#

class ChargeableUnitProperties < ActiveRecord::Base
  belongs_to :chargeable_unit, :polymorphic => true, :dependent => :destroy
  has_many :storage_charges, :order => "end_date ASC" # This way .first means the first ever charge, and .last means the last ever storage charge, by end_date

end
