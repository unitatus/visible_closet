class AddFedexValidationStatusToAddress < ActiveRecord::Migration
  def self.up
    add_column :addresses, :fedex_validation_status, :string
  end

  def self.down
    remove_column :addresses, :fedex_validation_status
  end
end
