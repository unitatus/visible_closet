class ChangePriceToDouble < ActiveRecord::Migration
  def self.up
    change_table :products do |t|
      t.change :price, :float
    end
  end

  def self.down
    change_table :products do |t|
      t.change :price, :integer
    end
  end
end
