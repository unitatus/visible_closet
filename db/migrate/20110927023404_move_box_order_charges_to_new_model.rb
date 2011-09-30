class MoveBoxOrderChargesToNewModel < ActiveRecord::Migration
  def self.up
    boxes = Box.find_all_by_box_type(Box::VC_BOX_TYPE)
    boxes.each do |box|
      charge = Charge.find_by_product_id_and_order_id(box.ordering_order_line.product_id, box.ordering_order_line.order_id)
      if charge
        charge.associate_with(box)
        charge.product_id = nil
        charge.order_id = nil
        charge.save
      end
    end
    
    # these are separate because they were actually executed at different times
    boxes = Box.all
    boxes.each do |box|
      if box.storage_charges.size > 0 && box.received_at
        storage_charge = box.storage_charges.first
        if storage_charge.start_date.nil?
          storage_charge.start_date = box.received_at
          amt_paid_in_months = box.current_subscription.nil? ? 1 : (box.current_subscription.duration_in_months < Discount::FREE_SHIPPING_MONTH_THRESHOLD ? box.current_subscription.duration_in_months : Discount::FREE_SHIPPING_MONTH_THRESHOLD)
          storage_charge.end_date = storage_charge.start_date.to_date >> amt_paid_in_months
          storage_charge.save
        end
      end
    end
  end

  def self.down
    # Ain't no going back.
  end
  
end
