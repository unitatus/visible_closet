class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.string :name
      t.string :type
      t.string :first_name
      t.string :last_name
      t.string :day_phone
      t.string :evening_phone
      t.string :address_line_1
      t.string :address_line_2
      t.string :city
      t.string :state
      t.string :zip

      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
