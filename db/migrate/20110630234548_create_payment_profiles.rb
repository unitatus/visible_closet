class CreatePaymentProfiles < ActiveRecord::Migration
  def self.up
    create_table :payment_profiles do |t|
      t.string :identifier
      t.string :last_four_digits
      t.integer :user_id, :references => :users

      t.timestamps
    end

      add_index :payment_profiles, :user_id
  end

  def self.down
    drop_table :payment_profiles
  end
end
