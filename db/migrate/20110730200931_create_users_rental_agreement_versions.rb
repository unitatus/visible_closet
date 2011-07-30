class CreateUsersRentalAgreementVersions < ActiveRecord::Migration
  def self.up
    create_table :users_rental_agreement_versions do |t|
      t.integer :user_id, :references => :users
      t.integer :rental_agreement_version_id, :references => :rental_agreement_versions

      t.timestamps
    end

    add_index :users_rental_agreement_versions, :user_id, :name => 'users_rav_user_index'
    add_index :users_rental_agreement_versions, :rental_agreement_version_id, :name => 'users_rav_rav_index'
  end

  def self.down
    drop_table :users_rental_agreement_versions
  end
end
