class ChangeHowBenefitBoxesTrack < ActiveRecord::Migration
  def self.up
    remove_column :free_storage_user_offer_benefit_boxes, :months_consumed
    add_column :free_storage_user_offer_benefit_boxes, :days_consumed, :integer
    add_column :free_storage_user_offer_benefit_boxes, :start_date, :datetime
  end

  def self.down
    add_column :free_storage_user_offer_benefit_boxes, :months_consumed, :integer
    remove_column :free_storage_user_offer_benefit_boxes, :days_consumed
    remove_column :free_storage_user_offer_benefit_boxes, :start_date
  end
end
