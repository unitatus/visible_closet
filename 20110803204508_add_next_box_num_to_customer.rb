class AddNextBoxNumToCustomer < ActiveRecord::Migration
  def self.up
    add_column :users, :last_box_num, :integer
  end

  def self.down
    remove_column :users, :last_box_num
  end
end
