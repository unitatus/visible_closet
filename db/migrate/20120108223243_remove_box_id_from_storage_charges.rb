class RemoveBoxIdFromStorageCharges < ActiveRecord::Migration
  def self.up
    StorageCharge.all.each do |storage_charge|
      storage_charge.chargeable_unit = Box.find(storage_charge.box_id) if storage_charge.box_id
      storage_charge.save
    end
    remove_column :storage_charges, :box_id
  end

  def self.down
    add_column :storage_charges, :box_id, :integer, :references => :boxes
    StorageCharge.all.each do |storage_charge|
      storage_charge.box_id = storage_charge.chargeable_unit.id if storage_charge.chargeable_unit && storage_charge.chargeable_unit_properties.chargeable_unit_type == 'Box'
      storage_charge.save
    end
  end
end
