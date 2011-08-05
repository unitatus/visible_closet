class RenameFieldsOnPaymentProfile < ActiveRecord::Migration
  def self.up
    rename_column :payment_profiles, :exp_month, :month
    rename_column :payment_profiles, :exp_year, :year
    rename_column :payment_profiles, :cc_type, :type
  end

  def self.down
    rename_column :payment_profiles, :month; :exp_month
    rename_column :payment_profiles, :year, :exp_year
    rename_column :payment_profiles, :type, :cc_type
  end
end
