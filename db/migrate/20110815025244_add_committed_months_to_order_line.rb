class AddCommittedMonthsToOrderLine < ActiveRecord::Migration
  def self.up
    add_column :order_lines, :committed_months, :integer
  end

  def self.down
    remove_column :order_lines, :committed_months
  end
end
