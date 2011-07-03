class AddNameToAddress < ActiveRecord::Migration
  def self.up
    add_column :addresses, :address_name, :string
  end

  def self.down
    remove_column :addresses, :address_name
  end
end
