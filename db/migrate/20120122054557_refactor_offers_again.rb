class RefactorOffersAgain < ActiveRecord::Migration
  def self.up
    add_column :offers, :start_date, :datetime
    add_column :offers, :expiration_date, :datetime
    add_column :offers, :created_by_user_id, :integer, :references => :users
    add_column :offers, :type, :string
    add_column :offers, :created_at, :datetime
    add_column :offers, :updated_at, :datetime
    remove_column :offer_benefits, :offer_properties_id
    add_column :offer_benefits, :offer_id, :integer, :references => :offers
    drop_table :offer_properties
  end

  def self.down
    create_table :offer_properties do |t|
      t.datetime :start_date
      t.datetime :expiration_date
      t.integer :created_by_user_id, :references => :users
      t.string :unique_identifier
      t.integer :offer_id
      t.string :offer_type
      t.timestamps
    end
    remove_column :offers, :start_date
    remove_column :offers, :expiration_date
    remove_column :offers, :created_by_user_id
    remove_column :offers, :type
    remove_column :offers, :created_at
    remove_column :offers, :updated_at
    add_column :offer_benefits, :offer_properties_id, :references => :offer_properties
    remove_column :offer_benefits, :offer_id
  end
end
