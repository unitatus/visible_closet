class AddActiveToPaymentProfile < ActiveRecord::Migration
  def self.up
    add_column :payment_profiles, :active, :boolean
  end

  def self.down
    remove_column :payment_profiles, :active
  end
end
