class CreateCoupons < ActiveRecord::Migration
  def self.up
    create_table :coupons do |t|
      t.integer :assigned_to_user_id, :references => :users
    end
  end

  def self.down
    drop_table :coupons
  end

end
