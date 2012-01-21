class MoveDescriptionToChargeableProperties < ActiveRecord::Migration
  def self.up
    rename_column :boxes, :description, :old_description
    rename_column :stored_items, :description, :old_description
    add_column :chargeable_unit_properties, :description, :string
    
    Box.all.each do |box|
      box.description = box.old_description
      box.save
    end
    
    FurnitureItem.all.each do |furniture_item|
      furniture_item.description = furniture_item.old_description
      furniture_item.save
    end
  end

  def self.down
    Box.all.each do |box|
      box.old_description = box.description if box.description
      box.save
    end
    
    FurnitureItem.all.each do |furniture_item|
      furniture_item.old_description = furniture_item.description if furniture_item.description
      furniture_item.save
    end
    
    rename_column :boxes, :old_description, :description
    rename_column :stored_items, :old_description, :description
    remove_column :chargeable_unit_properties, :description
  end
end
