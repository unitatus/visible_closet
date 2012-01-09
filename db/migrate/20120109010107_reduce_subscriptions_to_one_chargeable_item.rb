class ReduceSubscriptionsToOneChargeableItem < ActiveRecord::Migration
  def self.up
    Subscription.all.each do |subscription|
      subscription.boxes.each_with_index do |box, index|
        if index == 0
          subscription.chargeable_unit = box
          subscription.save
        else
          box.subscriptions.create!(:start_date => subscription.start_date, \
                                    :end_date => subscription.end_date, \
                                    :user_id => subscription.user_id, \
                                    :duration_in_months => subscription.duration_in_months, \
                                    :created_at => subscription.created_at, \
                                    :updated_at => subscription.updated_at)
        end
      end
      
      subscription.furniture_items.each_with_index do |furniture_item, index|
        if index == 0
          subscription.chargeable_unit = furniture_item
          subscription.save
        else
          furniture_item.subscriptions.create!(:start_date => subscription.start_date, \
                                    :end_date => subscription.end_date, \
                                    :user_id => subscription.user_id, \
                                    :duration_in_months => subscription.duration_in_months, \
                                    :created_at => subscription.created_at, \
                                    :updated_at => subscription.updated_at)
        end
      end
    end
  end

  def self.down
  end
end
