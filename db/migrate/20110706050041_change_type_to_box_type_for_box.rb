class ChangeTypeToBoxTypeForBox < ActiveRecord::Migration
  def self.up
    remove_column :boxes, :type
    add_column :boxes, :box_type, :string
  end

  def self.down
    remove_column :boxes, :box_type
    add_column :boxes, :type
  end
end
