class Discount
  MONTH_COUNT_DISCOUNT_THRESHOLD_1 = 3
  MONTH_COUNT_DISCOUNT_THRESHOLD_2 = 6
  MONTH_COUNT_DISCOUNT_THRESHOLD_3 = 12
  MONTH_COUNT_THRESHOLD_1_DISCOUNT = 0.0
  MONTH_COUNT_THRESHOLD_2_DISCOUNT = 0.1
  MONTH_COUNT_THRESHOLD_3_DISCOUNT = 0.1
  
  UNIT_COUNT_THRESHOLD_1_DISCOUNT = 0.05
  UNIT_COUNT_THRESHOLD_2_DISCOUNT = 0.1
  UNIT_COUNT_THRESHOLD_3_DISCOUNT = 0.1
  BOX_COUNT_DISCOUNT_THRESHOLD_1 = 5
  BOX_COUNT_DISCOUNT_THRESHOLD_2 = 15
  BOX_COUNT_DISCOUNT_THRESHOLD_3 = 30
  CF_DISCOUNT_THRESHOLD_1 = 10
  CF_DISCOUNT_THRESHOLD_2 = 30
  CF_DISCOUNT_THRESHOLD_3 = 60
  
  # Changed to 0 from 3 to reflect the fact that we always pay shipping now
  FREE_SHIPPING_MONTH_THRESHOLD = 0
  
  attr_accessor :product, :new_product_count, :month_count, :existing_product_count
  
  def Discount.new(product, new_product_count=0, month_count=0, existing_product_count=0)
    if product.nil?
      raise "Cannot instantiate with nil product"
    end
    
    month_count ||= 0
    new_product_count ||= 0
    existing_product_count ||= 0
    
    discount = super()
    
    discount.product = product
    discount.new_product_count = new_product_count
    discount.month_count = month_count
    discount.existing_product_count = existing_product_count
    
    return discount
  end
  
  def total_product_count
    return new_product_count + existing_product_count
  end
  
  def unit_discount_perc
    if !product.discountable?
      return 0.0
    end
    
    discount_perc = 0.0
    
    count_threshold_1, count_threshold_2, count_threshold_3 = determine_thresholds
    
    # The to_f's are for the case where product count or month count are not set
    discount_perc += UNIT_COUNT_THRESHOLD_1_DISCOUNT if self.total_product_count.to_f >= count_threshold_1
    discount_perc += UNIT_COUNT_THRESHOLD_2_DISCOUNT if self.total_product_count.to_f >= count_threshold_2
    discount_perc += UNIT_COUNT_THRESHOLD_3_DISCOUNT if self.total_product_count.to_f >= count_threshold_3
    discount_perc += MONTH_COUNT_THRESHOLD_1_DISCOUNT if @month_count.to_f >= MONTH_COUNT_DISCOUNT_THRESHOLD_1
    discount_perc += MONTH_COUNT_THRESHOLD_2_DISCOUNT if @month_count.to_f >= MONTH_COUNT_DISCOUNT_THRESHOLD_2
    discount_perc += MONTH_COUNT_THRESHOLD_3_DISCOUNT if @month_count.to_f >= MONTH_COUNT_DISCOUNT_THRESHOLD_3
    
    return discount_perc
  end
  
  def unit_discount_dollars
    return @product.price * self.unit_discount_perc
  end
  
  def unit_price_after_discount
    return @product.price - self.unit_discount_dollars
  end
  
  def total_monthly_savings
    return self.unit_discount_dollars * @new_product_count
  end
  
  def total_monthly_price_after_discount
    return self.unit_price_after_discount * @new_product_count
  end
  
  def total_period_savings
    return self.total_monthly_savings * @month_count
  end
  
  def total_period_price_after_discount
    return self.total_monthly_price_after_discount * @month_count
  end
  
  def months_due_at_signup
    if @month_count.to_f >= FREE_SHIPPING_MONTH_THRESHOLD
      return FREE_SHIPPING_MONTH_THRESHOLD
    elsif @product.prepay?
      return 1
    else
      return 0
    end
  end
  
  def prepaid_at_purchase
    if @product.prepay? || self.month_count.to_f >= FREE_SHIPPING_MONTH_THRESHOLD
			self.total_monthly_price_after_discount * months_due_at_signup
		else
		  return 0.0
		end
  end
  
  def charged_at_purchase
    product.incurs_charge_at_purchase? ? @product.price*@new_product_count : 0.0
  end
  
  def free_shipping?
    return self.month_count >= FREE_SHIPPING_MONTH_THRESHOLD
  end
  
  def free_shipping_materials?
    return @product.vc_box?
  end
  
  private 
  
  def determine_thresholds
    if @product.vc_box? || @product.vc_inventorying?
      [BOX_COUNT_DISCOUNT_THRESHOLD_1, BOX_COUNT_DISCOUNT_THRESHOLD_2, BOX_COUNT_DISCOUNT_THRESHOLD_3]
    else
      [CF_DISCOUNT_THRESHOLD_1, CF_DISCOUNT_THRESHOLD_2, CF_DISCOUNT_THRESHOLD_3]
    end
  end  
end