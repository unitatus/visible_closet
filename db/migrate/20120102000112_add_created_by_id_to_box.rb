class AddCreatedByIdToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :created_by_id, :integer, :references => :users
  end

  def self.down
    remove_column :boxes, :created_by_id
  end
end
