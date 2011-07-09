class RemoveInsuredFromBoxes < ActiveRecord::Migration
  def self.up
   remove_column :boxes, :insured 
  end

  def self.down
   add_column :boxes, :insured, :boolean
  end
end
