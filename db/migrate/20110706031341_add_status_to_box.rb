class AddStatusToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :status, :string
  end

  def self.down
    remove_column :boxes, :status
  end
end
