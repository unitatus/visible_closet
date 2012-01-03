class AddVisibilityToStoredItemPhoto < ActiveRecord::Migration
  def self.up
    add_column :stored_item_photos, :visibility, :string
    StoredItemPhoto.all.each do |photo|
      photo.update_attribute(:visibility, StoredItemPhoto::CUSTOMER_VISIBILITY)
    end
  end

  def self.down
    remove_column :stored_item_photos, :visibility
  end
end
