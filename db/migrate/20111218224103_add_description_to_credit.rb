class AddDescriptionToCredit < ActiveRecord::Migration
  def self.up
    add_column :credits, :description, :string
  end

  def self.down
    remove_column :credits, :description
  end
end
