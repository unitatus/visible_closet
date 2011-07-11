class CreateStoredItemTag < ActiveRecord::Migration
  def self.up
    create_table :stored_item_tags do |t|
      t.integer :stored_item_id, :references => :stored_items
      t.string :tag

      t.timestamps
    end
  end

  def self.down
    drop_table :stored_item_tags
  end
end
