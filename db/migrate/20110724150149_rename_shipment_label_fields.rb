class RenameShipmentLabelFields < ActiveRecord::Migration
  def self.up
    rename_column :shipments, :label_file_name, :shipment_label_file_name
    rename_column :shipments, :label_content_type, :shipment_label_content_type
    rename_column :shipments, :label_file_size, :shipment_label_file_size
    rename_column :shipments, :label_updated_at, :shipment_label_updated_at
  end

  def self.down
    rename_column :shipments, :shipment_label_file_name, :label_file_name
    rename_column :shipments, :shipment_label_content_type, :label_content_type
    rename_column :shipments, :shipment_label_file_size, :label_file_size
    rename_column :shipments, :shipment_label_updated_at, :label_updated_at
  end
end
