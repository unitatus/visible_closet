class Event  
  attr_accessor :description, :date
  
  def Event.new(attributes={})
    event = super
    
    if attributes[:date]
      event.date = attributes[:date]
    end
    
    if attributes[:description]
      event.description = attributes[:description]
    end
    
    return event
  end
  
  def Event.all(user)
    all_events = Array.new
    
    user.boxes.each do |box|
      all_events << Event.new(:description => "Box #{box.box_num} ordered", :date => box.created_at.to_date)
      
      if box.received_at
        all_events << Event.new(:description => "Box #{box.box_num} received", :date => box.received_at.to_date)
      end
      
      if box.inventoried_at
        all_events << Event.new(:description => "Box #{box.box_num} inventoried", :date => box.inventoried_at.to_date)
      end
      
      if box.return_requested_at
        all_events << Event.new(:description => "Box #{box.box_num} return requested", :date => box.return_requested_at.to_date)
      end
    end
    
    user.charges.each do |charge|
      msg = "Charge of #{ActionController::Base.helpers.number_to_currency(charge.amount)} for "
      
			if charge.product_id
			  msg += "purchase of #{charge.product.name}"
			elsif charge.shipment
				msg += "shipping for "
			  if charge.shipment.box_id
					msg += "box #{charge.shipment.box.box_num}"
				elsif charge.order
          msg += "order #{charge.order_id}"
				else
					msg += "(unknown shipment type)"
			  end
			elsif charge.order_id
				msg += "order #{charge.order_id}"
			else # storage charge or misc
			  msg += charge.comments
		  end # end if
		  
		  if charge.storage_charge
		    msg += " for storage starting #{charge.storage_charge.start_date.strftime('%m/%d/%Y')} and ending #{charge.storage_charge.start_date.strftime('%m/%d/%Y')}"
	    end
		  
		  all_events << Event.new(:description => msg, :date => charge.created_at.to_date)
    end # end loop on charges
    
    user.successful_payment_transactions.each do |payment|
      msg = "Payment of #{ActionController::Base.helpers.number_to_currency(payment.credit.amount)} for "
      if payment.order_id
        msg += "order #{payment.order_id}"
      elsif payment.credit.description
        msg += payment.credit.description
      else
        msg += "storage charges"
      end
      all_events << Event.new(:description => msg, :date => payment.created_at.to_date)
    end
    
    credits = user.credits.select {|credit| credit.payment_transaction.nil? }
    credits.each do |credit|
      all_events << Event.new(:description => "Credit of #{ActionController::Base.helpers.number_to_currency(credit.amount)} for \"#{credit.description}\"", :date => credit.created_at.to_date) 
    end
    
    return all_events.sort {|x,y| y.date <=> x.date }
  end # end method
end