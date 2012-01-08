class CreateDimensionSet < ActiveRecord::Migration
  def self.up
    create_table :dimension_sets do |t|
          t.float :new_height
          t.float :new_width
          t.float :new_length
          t.string :new_location
          t.integer :measured_object_id
          t.string :measured_object_type
    end
  end

  def self.down
    drop_table :dimension_sets
  end

end
