module DateHelper
  def DateHelper.end_of_month(date=nil)
    if date.nil?
      date = Date.today
    end
    
    Date.parse((date.month == 12 ? date.year + 1 : date.year).to_s + "-" + (date.month == 12 ? 1 : date.month + 1).to_s + "-01") - 1
  end
  
  def DateHelper.end_of_last_month(date=nil)
    if date.nil?
      date = Date.today
    end
    
    end_of_month(date << 1)
  end
  
  def DateHelper.start_of_month(date=nil)
    if date.nil?
      date = Date.today
    end
    
    end_of_last_month(date) + 1
  end
end