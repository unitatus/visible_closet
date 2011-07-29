class AddPaymentProfileIdToPaymentTransaction < ActiveRecord::Migration
  def self.up
    add_column :payment_transactions, :payment_profile_id, :integer, :references => :payment_profiles
  end

  def self.down
    remove_column :payment_transactions, :payment_profile_id
  end
end
