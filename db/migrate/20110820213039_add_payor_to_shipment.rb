class AddPayorToShipment < ActiveRecord::Migration
  def self.up
    add_column :shipments, :payor, :string
  end

  def self.down
    remove_column :shipments, :payor
  end
end
