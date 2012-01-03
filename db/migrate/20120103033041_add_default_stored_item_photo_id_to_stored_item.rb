class AddDefaultStoredItemPhotoIdToStoredItem < ActiveRecord::Migration
  def self.up
    add_column :stored_items, :default_customer_stored_item_photo_id, :integer, :references => :stored_item_photos
    add_column :stored_items, :default_admin_stored_item_photo_id, :integer, :references => :stored_item_photos
  end

  def self.down
    remove_column :stored_items, :default_customer_stored_item_photo_id
    remove_column :stored_items, :default_admin_stored_item_photo_id
  end
end
