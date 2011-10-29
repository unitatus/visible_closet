class AddDiscountableToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :discountable, :boolean
  end

  def self.down
    remove_column :products, :discountable
  end
end
