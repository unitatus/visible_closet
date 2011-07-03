class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|
      t.references :stored_item
      t.timestamps
    end

    add_index :photos, :stored_item_id
  end

  def self.down
    drop_table :photos
  end
end
