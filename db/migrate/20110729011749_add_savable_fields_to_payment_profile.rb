class AddSavableFieldsToPaymentProfile < ActiveRecord::Migration
  def self.up
    add_column :payment_profiles, :type, :string
    add_column :payment_profiles, :exp_month, :integer
    add_column :payment_profiles, :exp_year, :integer
    add_column :payment_profiles, :first_name, :string
    add_column :payment_profiles, :last_name, :string
    add_column :payment_profiles, :billing_address_id, :integer, :references => :addresses
  end

  def self.down
    remove_column :payment_profiles, :type
    remove_column :payment_profiles, :exp_month
    remove_column :payment_profiles, :exp_year
    remove_column :payment_profiles, :first_name
    remove_column :payment_profiles, :last_name
    remove_column :payment_profiles, :billing_address_id
  end
end
