class ChangeTypeToCcTypeOnPaymentProfiles < ActiveRecord::Migration
  def self.up
    add_column :payment_profiles, :cc_type, :string
    remove_column :payment_profiles, :type
  end

  def self.down
    remove_column :payment_profiles, :cc_type
    add_column :payment_prifiles, :type, :string
  end
end
