class RemoveNameFromAddress < ActiveRecord::Migration
  def self.up
    remove_column :addresses, :name
  end

  def self.down
    add_column :addresses, :name, :string
  end
end
