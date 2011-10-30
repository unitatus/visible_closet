class AddDonatedToToStoredItem < ActiveRecord::Migration
  def self.up
    add_column :stored_items, :donated_to, :string
  end

  def self.down
    remove_column :stored_items, :donated_to
  end
end
