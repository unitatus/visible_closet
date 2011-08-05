class AddFirstDueToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :first_due, :string
  end

  def self.down
    remove_column :products, :first_due
  end
end
