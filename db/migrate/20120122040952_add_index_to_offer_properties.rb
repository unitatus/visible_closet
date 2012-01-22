class AddIndexToOfferProperties < ActiveRecord::Migration
  def self.up
    add_index :offer_properties, :unique_identifier
  end

  def self.down
    remove_index :offer_properties, :unique_identifier
  end
end
