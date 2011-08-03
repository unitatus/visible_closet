class AddBoxNumToBox < ActiveRecord::Migration
  def self.up
    add_column :boxes, :box_num, :integer
  end

  def self.down
    remove_column :boxes, :box_num
  end
end
