class AddLabelLastEmailedToShipment < ActiveRecord::Migration
  def self.up
    add_column :shipments, :last_label_emailed, :datetime
  end

  def self.down
    remove_column :shipments, :last_label_emailed
  end
end
