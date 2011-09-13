class AddCommentsToCharge < ActiveRecord::Migration
  def self.up
    add_column :charges, :comments, :string
  end

  def self.down
    remove_column :charges, :comments
  end
end
