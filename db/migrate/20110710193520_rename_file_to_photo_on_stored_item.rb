class RenameFileToPhotoOnStoredItem < ActiveRecord::Migration
  def self.up
    rename_column :stored_items, :file_file_name, :photo_file_name
    rename_column :stored_items, :file_content_type, :photo_content_type
    rename_column :stored_items, :file_file_size, :photo_file_size
    rename_column :stored_items, :file_updated_at, :photo_updated_at
  end

  def self.down
    rename_column :stored_items, :photo_file_name, :file_file_name
    rename_column :stored_items, :photo_content_type, :file_content_type
    rename_column :stored_items, :photo_file_size, :file_file_size
    rename_column :stored_items, :photo_updated_at, :file_updated_at
  end
end
