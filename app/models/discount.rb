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
  
  FREE_SHIPPING_MONTH_THRESHOLD = 3
  
  attr_accessor :product, :product_count, :month_count
  
  def Discount.new(product, product_count, month_count)
    if product.nil?
      raise "Cannot instantiate with nil product"
    end
    
    if product_count.nil?
      @product_count = 0
    end
    
    if month_count.nil?
      @month_count = 0
    end
    
    discount = super()
    
    discount.product = product
    discount.product_count = product_count
    discount.month_count = month_count
    
    return discount
  end
  
  def unit_discount_perc
    discount_perc = 0.0
    
    count_threshold_1, count_threshold_2, count_threshold_3 = determine_thresholds
    
    discount_perc += UNIT_COUNT_THRESHOLD_1_DISCOUNT if @product_count >= count_threshold_1
    discount_perc += UNIT_COUNT_THRESHOLD_2_DISCOUNT if @product_count >= count_threshold_2
    discount_perc += UNIT_COUNT_THRESHOLD_3_DISCOUNT if @product_count >= count_threshold_3
    discount_perc += MONTH_COUNT_THRESHOLD_1_DISCOUNT if @month_count >= MONTH_COUNT_DISCOUNT_THRESHOLD_1
    discount_perc += MONTH_COUNT_THRESHOLD_2_DISCOUNT if @month_count >= MONTH_COUNT_DISCOUNT_THRESHOLD_2
    discount_perc += MONTH_COUNT_THRESHOLD_3_DISCOUNT if @month_count >= MONTH_COUNT_DISCOUNT_THRESHOLD_3
    
    return discount_perc
  end
  
  def unit_discount_dollars
    return ((@product.price * self.unit_discount_perc)*100.0).floor/100.0
  end
  
  def unit_price_after_discount
    return @product.price - self.unit_discount_dollars
  end
  
  def total_monthly_savings
    return self.unit_discount_dollars * @product_count
  end
  
  def total_monthly_price_after_discount
    return self.unit_price_after_discount * @product_count
  end
  
  def total_period_savings
    return self.total_monthly_savings * @month_count
  end
  
  def total_period_price_after_discount
    return self.total_monthly_price_after_discount * @month_count
  end
  
  def months_due_at_signup
    if @month_count >= FREE_SHIPPING_MONTH_THRESHOLD
      return FREE_SHIPPING_MONTH_THRESHOLD
    else
      return 1
    end
  end
  
  def due_at_signup
    if product.first_due == Product::AT_SIGNUP || self.month_count >= FREE_SHIPPING_MONTH_THRESHOLD
			self.total_monthly_price_after_discount * months_due_at_signup
		else
		  return 0.0
		end
  end
  
  def free_shipping?
    return self.month_count >= FREE_SHIPPING_MONTH_THRESHOLD
  end
  
  private 
  
  def determine_thresholds
    if @product.id == Rails.application.config.our_box_product_id || @product.id == Rails.application.config.our_box_inventorying_product_id
      [BOX_COUNT_DISCOUNT_THRESHOLD_1, BOX_COUNT_DISCOUNT_THRESHOLD_2, BOX_COUNT_DISCOUNT_THRESHOLD_3]
    else
      [CF_DISCOUNT_THRESHOLD_1, CF_DISCOUNT_THRESHOLD_2, CF_DISCOUNT_THRESHOLD_3]
    end
  end  
end