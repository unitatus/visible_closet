class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.datetime :start_date
      t.datetime :end_date
      t.integer :user_id, :references => :users
      t.integer :duration_in_months

      t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
