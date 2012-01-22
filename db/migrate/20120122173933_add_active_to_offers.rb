class AddActiveToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :active, :boolean
  end

  def self.down
    remove_column :offers, :active
  end
end
