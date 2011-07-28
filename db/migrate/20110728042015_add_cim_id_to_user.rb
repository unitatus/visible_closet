class AddCimIdToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :cim_id, :string
  end

  def self.down
    remove_column :users, :cim_id
  end
end
