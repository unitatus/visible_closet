class AddIndexingStatusToBoxes < ActiveRecord::Migration
  def self.up
    add_column :boxes, :indexing_status, :string
  end

  def self.down
    remove_column :boxes, :indexing_status
  end
end
