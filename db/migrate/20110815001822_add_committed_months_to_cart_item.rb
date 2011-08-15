class AddCommittedMonthsToCartItem < ActiveRecord::Migration
  def self.up
    add_column :cart_items, :committed_months, :integer
  end

  def self.down
    remove_column :cart_items, :committed_months
  end
end
