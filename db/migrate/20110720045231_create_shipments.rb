class CreateShipments < ActiveRecord::Migration
  def self.up
    create_table :shipments do |t|
      t.integer :box_id, :references => :boxes
      t.integer :from_address_id, :references => :addresses
      t.integer :to_address_id, :references => :addresses
      t.string :tracking_number

      t.timestamps
    end

    add_index :shipments, :box_id
    add_index :shipments, :from_address_id
    add_index :shipments, :to_address_id
    add_index :shipments, :tracking_number
  end

  def self.down
    drop_table :shipments
  end
end
