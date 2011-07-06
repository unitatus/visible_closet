class AddTypeToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :type, :string
  end

  def self.down
    remove_column :boxes, :type
  end
end
