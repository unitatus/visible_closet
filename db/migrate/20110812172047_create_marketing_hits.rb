class CreateMarketingHits < ActiveRecord::Migration
  def self.up
    create_table :marketing_hits do |t|
      t.string :source

      t.timestamps
    end
  end

  def self.down
    drop_table :marketing_hits
  end
end
