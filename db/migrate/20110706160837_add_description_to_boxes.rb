class AddDescriptionToBoxes < ActiveRecord::Migration
  def self.up
    add_column :boxes, :description, :text
  end

  def self.down
    remove_column :boxes, :description
  end
end
