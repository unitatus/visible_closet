class ChangeChargeTotalType < ActiveRecord::Migration
  def self.up
    change_column :charges, :total_in_cents, :float
  end

  def self.down
    change_column :charges, :total_in_cents, :integer
  end
end
