class CreateStoredItemPhoto < ActiveRecord::Migration
  def self.up
    create_table :stored_item_photos do |t|
          t.string :photo_file_name
          t.string :photo_content_type
          t.integer :photo_file_size
          t.datetime :photo_updated_at
          t.string :access_token
          t.integer :stored_item_id, :references => :stored_items
          t.timestamps
        end
      end

  def self.down
    drop_table :stored_item_photos
  end
end
