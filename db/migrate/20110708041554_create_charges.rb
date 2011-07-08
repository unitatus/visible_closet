class CreateCharges < ActiveRecord::Migration
  def self.up
    create_table :charges do |t|
      t.integer :user_id, :references => :users
      t.integer :total_in_cents
      t.integer :product_id, :references => :products

      t.timestamps
    end
  end

  def self.down
    drop_table :charges
  end
end
