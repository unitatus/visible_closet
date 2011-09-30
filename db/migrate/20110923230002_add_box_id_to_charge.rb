class AddBoxIdToCharge < ActiveRecord::Migration
  def self.up
    add_column :charges, :box_id, :integer, :references => :boxes
  end

  def self.down
    remove_column :charges, :box_id
  end
end
