class CreateOffers < ActiveRecord::Migration
  def self.up
    create_table :offers do |t|
    end
  end

  def self.down
    drop_table :offers
  end

end
