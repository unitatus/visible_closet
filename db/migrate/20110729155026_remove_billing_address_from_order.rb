class RemoveBillingAddressFromOrder < ActiveRecord::Migration
  def self.up
    remove_column :orders, :billing_address_id
  end

  def self.down
    add_column :orders, :billing_address_id, :integer, :references => :addresses
  end
end
