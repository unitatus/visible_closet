class AddLocationToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :location, :string
  end

  def self.down
    remove_column :boxes, :location
  end
end
