class AddSnapshotUserIdToAddresses < ActiveRecord::Migration
  def self.up
    add_column :addresses, :snapshot_user_id, :integer, :references => :users

    Address.all.each do |address|
      if address.snapshot_user_id.nil?
        address.snapshot_user_id = address.user_id
        address.innocuous_save
      end

      if address.snapshot_user_id.nil?
        address.to_shipments.each do |shipment|
          if shipment.box
            if shipment.box.assigned_to_user_id and address.snapshot_user_id.nil?
              address.snapshot_user_id = shipment.box.assigned_to_user_id
              address.innocuous_save
            end
          end
        end
      end

      if address.snapshot_user_id.nil?
        address.from_shipments.each do |shipment|
          if shipment.box
            if shipment.box.assigned_to_user_id and address.snapshot_user_id.nil?
              address.snapshot_user_id = shipment.box.assigned_to_user_id
              address.innocuous_save
            end
          end
        end
      end

      if address.snapshot_user_id.nil?
        address.payment_profiles.each do |payment_profile|
          address.snapshot_user_id = payment_profile.user_id
          address.innocuous_save
        end
      end
    end
  end

  def self.down
    remove_column :addresses, :snapshot_user_id
  end
end
