class AddDefaultPaymentProfileIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :default_payment_profile_id, :integer, :references => :payment_profiles
  end

  def self.down
    remove_column :users, :default_payment_profile_id
  end
end
