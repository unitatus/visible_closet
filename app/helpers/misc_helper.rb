module MiscHelper
  def MiscHelper.aggregate_transactions(transactions)
    running_total = 0.0
    
    transactions.each do |transaction|
      running_total += transaction.amount.to_f
    end
    
    return running_total
  end
  
  def MiscHelper.contains_shipping_lines(order_lines)
    order_lines.each do |order_line|
      if order_line.shippable?
        return true
      end
    end
    
    return false
  end
  
  def MiscHelper.contains_non_shipping_item_services(order_lines)
    order_lines.each do |order_line|
      if !order_line.shippable? && order_line.item_service?
        return true
      end
    end
    
    return false
  end
  
  def MiscHelper.contains_item_mailings(order_lines)
    order_lines.each do |order_line|
      if order_line.item_mailing?
        return true
      end
    end
    
    return false
  end
end