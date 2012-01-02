class RemovePhotoColumnsFromStoredItem < ActiveRecord::Migration
  def self.up
    remove_column :stored_items, :photo_file_name
    remove_column :stored_items, :photo_content_type
    remove_column :stored_items, :photo_file_size
    remove_column :stored_items, :photo_updated_at
    remove_column :stored_items, :access_token
  end

  def self.down
    add_column :stored_items, :photo_file_name, :string
    add_column :stored_items, :photo_content_type, :string
    add_column :stored_items, :photo_file_size, :integer
    add_column :stored_items, :photo_updated_at, :datetime
    add_column :stored_items, :access_token, :string
  end
end
