class Date
  def Date.months_between(start_date, end_date)
    if start_date.nil? || end_date.nil? || start_date > end_date
      return nil
    end
    
    # take care of datetime objects
    start_date = start_date.to_date
    end_date = end_date.to_date
    
    years, months, days = (end_date.year - start_date.year), (end_date.month - start_date.month), (end_date.day - start_date.day)

    # days should be inclusive
    # days += 1
    
    months = months - 1 if days < 0
    years, months = (years - 1), (months + 12) if months < 0
        
    if days < 0
      days = days_in_month(start_date.month, start_date.year) - start_date.day + end_date.day
    end    
    
    if start_date + 1.months > end_date
      months_remainder = ((start_date + 1.month) - start_date).to_i
    else
      months_remainder = ((start_date + years.years + months.months + 1.months) - (start_date + years.years + months.months)).to_i
    end

    return Rational(years * 12 + months) + Rational(days, months_remainder)
  end
  
  def Date.days_in_month(month, year)
    this_month = Date.parse(year.to_s + "-" + month.to_s + "-01")
    ((this_month >> 1) - 1).day
  end
end