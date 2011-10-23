class UpdateStoredItemStatuses < ActiveRecord::Migration
  def self.up
    StoredItem.all.each do |stored_item|
      stored_item.update_attribute(:status, StoredItem::IN_STORAGE_STATUS)
    end
  end

  def self.down
    StoredItem.all.each do |stored_item|
      stored_item.update_attribute(:status, nil)
    end
  end
end
