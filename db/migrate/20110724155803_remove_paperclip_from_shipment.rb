class RemovePaperclipFromShipment < ActiveRecord::Migration
  def self.up
    remove_column :shipments, :shipment_label_content_type
    remove_column :shipments, :shipment_label_file_size
  end

  def self.down
    add_column shipments, :shipment_label_content_type, :string
    add_column shipments, :shipment_label_file_Size, :integer
  end
end
