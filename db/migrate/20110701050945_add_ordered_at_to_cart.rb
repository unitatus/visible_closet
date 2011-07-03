class AddOrderedAtToCart < ActiveRecord::Migration
  def self.up
    add_column :carts, :ordered_at, :datetime
  end

  def self.down
    remove_column :carts, :ordered_at
  end
end
