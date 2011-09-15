class AddReturnRequestedAtToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :return_requested_at, :datetime
  end

  def self.down
    remove_column :boxes, :return_requested_at
  end
end
