class CreateBoxes < ActiveRecord::Migration
  def self.up
    create_table :boxes do |t|
      t.integer :assigned_to_user_id, :references => :users

      t.timestamps
    end

    add_index :boxes, :assigned_to_user_id
  end

  def self.down
    drop_table :boxes
  end
end
