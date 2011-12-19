class AddCreatedByAdminIdToCredit < ActiveRecord::Migration
  def self.up
    add_column :credits, :created_by_admin_id, :integer, :references => :users
  end

  def self.down
    remove_column :credits, :created_by_admin_id
  end
end
