class CreateOrderLines < ActiveRecord::Migration
  def self.up
    create_table :order_lines do |t|
      t.integer :order_id, :references => :orders
      t.integer :product_id, :references => :products
      t.integer :quantity
      t.string :status

      t.timestamps
    end

    add_index :order_lines, :order_id
    add_index :order_lines, :product_id
  end

  def self.down
    drop_table :order_lines
  end
end
