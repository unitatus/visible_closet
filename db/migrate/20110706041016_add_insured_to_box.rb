class AddInsuredToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :insured, :boolean
  end

  def self.down
    remove_column :boxes, :insured
  end
end
