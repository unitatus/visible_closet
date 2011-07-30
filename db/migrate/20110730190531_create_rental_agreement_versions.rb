class CreateRentalAgreementVersions < ActiveRecord::Migration
  def self.up
    create_table :rental_agreement_versions do |t|
      t.text :agreement_text

      t.timestamps
    end
  end

  def self.down
    drop_table :rental_agreement_versions
  end
end
