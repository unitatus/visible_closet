class SwitchReceivedAtToCharging < ActiveRecord::Migration
  def self.up
    Box.all.each do |box|
      box.charging_start_date = box.received_at
      box.save
    end
  end

  def self.down
  end
end
