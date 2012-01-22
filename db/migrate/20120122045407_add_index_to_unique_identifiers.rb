class AddIndexToUniqueIdentifiers < ActiveRecord::Migration
  def self.up
    add_index :offers, :unique_identifier
    add_index :coupons, :unique_identifier
  end

  def self.down
    remove_index :offers, :unique_identifier
    remove_index :coupons, :unique_identifier
  end
end
