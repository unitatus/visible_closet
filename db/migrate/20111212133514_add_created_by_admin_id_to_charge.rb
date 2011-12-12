class AddCreatedByAdminIdToCharge < ActiveRecord::Migration
  def self.up
    add_column :charges, :created_by_admin_id, :integer, :references => :users
  end

  def self.down
    remove_column :charges, :created_by_admin_id
  end
end
