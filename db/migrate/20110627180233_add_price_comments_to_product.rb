class AddPriceCommentsToProduct < ActiveRecord::Migration
  def self.up
    add_column :products, :price_comment, :string
  end

  def self.down
    remove_column :products, :price_comment
  end
end
