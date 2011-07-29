class ChangeExpMonthToStringOnPaymentProfiles < ActiveRecord::Migration
  def self.up
    remove_column :payment_profiles, :exp_month
    add_column :payment_profiles, :exp_month, :string
  end

  def self.down
    remove_column :payment_profiles, :exp_month
    add_column :payment_profiles, :exp_month, :integer
  end
end
