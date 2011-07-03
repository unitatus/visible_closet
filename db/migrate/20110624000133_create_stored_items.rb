class CreateStoredItems < ActiveRecord::Migration
  def self.up
    create_table :stored_items do |t|
      t.references :box
      t.timestamps
    end

    add_index :stored_items, :box_id
  end

  def self.down
    drop_table :stored_items
  end
end
