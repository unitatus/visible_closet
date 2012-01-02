class MoveStoredItemPhotoDataToStoredItemPhoto < ActiveRecord::Migration
  def self.up
    StoredItem.all.each do |stored_item|
      stored_item_photo = StoredItemPhoto.new(:photo_file_name => stored_item.photo_file_name,
                                              :photo_content_type => stored_item.photo_content_type,
                                              :photo_file_size => stored_item.photo_file_size,
                                              :photo_updated_at => stored_item.photo_updated_at)
      stored_item_photo.id = stored_item.id # for paperclip path
      stored_item_photo.save
      stored_item_photo.access_token = stored_item.access_token
      stored_item_photo.created_at = stored_item.created_at
      stored_item_photo.updated_at = stored_item.updated_at
      stored_item_photo.save
      
      stored_item.stored_item_photos << stored_item_photo
    end
  end

  def self.down
    StoredItem.all.each do |stored_item|
      stored_item.photo_file_name = stored_item.stored_item_photo.photo_file_name if stored_item.stored_item_photo
      stored_item.photo_content_type = stored_item.stored_item_photo.photo_content_type if stored_item.stored_item_photo
      stored_item.photo_file_size = stored_item.stored_item_photo.photo_file_size if stored_item.stored_item_photo
      stored_item.photo_updated_at = stored_item.stored_item_photo.photo_updated_at if stored_item.stored_item_photo
      stored_item.access_token = stored_item.stored_item_photo.access_token if stored_item.stored_item_photo
      stored_item.save
      stored_item.stored_item_photo.destroy if stored_item.stored_item_photo
    end
  end
end
