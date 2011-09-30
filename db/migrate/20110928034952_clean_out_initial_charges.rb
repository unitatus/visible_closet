class CleanOutInitialCharges < ActiveRecord::Migration
  def self.up
    # We are getting rid of the practice of charging for anything that has not actually been delivered yet, especially box storage costs. This makes life a lot easier. Instead,
    # customers pre-pay for however many months they need to.
    Box.all.each do |box|
      if box.storage_charges.size > 0
        box.storage_charges.first.charge.destroy # destroy the charge and the storage charge will follow
      end
    end
  end

  def self.down
  end
end
