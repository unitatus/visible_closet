# == Schema Information
# Schema version: 20120108183638
#
# Table name: dimension_sets
#
#  id                   :integer         not null, primary key
#  height               :float
#  width                :float
#  length               :float
#  location             :string(255)
#  measured_object_id   :integer
#  measured_object_type :string(255)
#

class ChargeableUnitProperties < ActiveRecord::Base
  belongs_to :chargeable_unit, :polymorphic => true, :dependent => :destroy

end
