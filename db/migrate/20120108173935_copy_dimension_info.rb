class CopyDimensionInfo < ActiveRecord::Migration
  def self.up
    Box.all.each do |box|
      box.new_height = box.height
      box.new_width = box.width
      box.new_length = box.length
      box.new_location = box.location
      box.save
    end

    FurnitureItem.all.each do |furniture_item|
      furniture_item.new_height = furniture_item.height
      furniture_item.new_width = furniture_item.width
      furniture_item.new_length = furniture_item.length
      furniture_item.new_location = furniture_item.location
      furniture_item.save
    end
  end

  def self.down
    Box.all.each do |box|
      box.height = box.new_height
      box.width = box.new_width
      box.length = box.new_length
      box.location = box.new_location
      box.save
    end

    FurnitureItem.all.each do |furniture_item|
      furniture_item.height = furniture_item.new_height
      furniture_item.width = furniture_item.new_width
      furniture_item.length = furniture_item.new_length
      furniture_item.location = furniture_item.new_location
      furniture_item.save
    end
  end
end
