class ChangeTypeBackToCcTypeForPaymentProfile < ActiveRecord::Migration
  def self.up
    rename_column :payment_profiles, :type, :cc_type
  end

  def self.down
    rename_column :payment_profiles, :cc_type, :type
  end
end
