class AddChargingEndDateToChargable < ActiveRecord::Migration
  def self.up
    add_column :chargeable_unit_properties, :charging_end_date, :datetime
    Box.all.each do |box|
      box.charging_end_date = box.return_requested_at
      box.save
    end
  end

  def self.down
    remove_column :chargeable_unit_properties, :charging_end_date
  end
end
