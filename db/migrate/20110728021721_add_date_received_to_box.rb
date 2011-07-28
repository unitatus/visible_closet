class AddDateReceivedToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :received_at, :datetime
  end

  def self.down
    remove_column :boxes, :received_at
  end
end
