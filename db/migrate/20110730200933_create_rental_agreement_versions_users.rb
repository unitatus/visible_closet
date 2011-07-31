class CreateRentalAgreementVersionsUsers < ActiveRecord::Migration
  def self.up
    # Had naming problem -- comment this in if rollback is necessary.
    # create_table :rental_agreement_versions_users, :id => false do |t|
    #       t.integer :user_id, :references => :users
    #       t.integer :rental_agreement_version_id, :references => :rental_agreement_versions
    # 
    #       t.timestamps
    # end

    # add_index :rental_agreement_versions_users, :user_id, :name => 'users_rav_user_index'
    #     add_index :rental_agreement_versions_users, :rental_agreement_version_id, :name => 'users_rav_rav_index'
  end

  def self.down
    # drop_table :rental_agreement_versions_users
  end
end
