class AddStatusToCart < ActiveRecord::Migration
  def self.up
    add_column :carts, :status, :string
  end

  def self.down
    remove_column :carts, :status
  end
end
