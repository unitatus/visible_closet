module ApplicationHelper
  def error_messages_for_attribute(object, attribute)
    # if (object.kind_of? ActiveRecord::Base || object.kind_of? ActiveMerchant::Validateable::Errors)
      error_messages = object.errors[attribute]
    # else # ???
      # error_messages = object.errors.raw(attribute)
    # end

    if (error_messages)
      html = '<div class="error_label">'
      error_messages.each do |message|
        html += message + "<br>"
      end
      html += "</div>"
    end

    # By default html strings are escaped in rails. Use raw function to reverse that.
    raw html
  end

  def states_array
    ['AK',
	'AL',
	'AR',
	'AZ',
	'CA',
	'CO',
	'CT',
	'DC',
	'DE',
	'FL',
	'GA',
	'HI',
	'IA',
	'ID',
	'IL',
	'IN',
	'KS',
	'KY',
	'LA',
	'MA',
	'MD',
	'ME',
	'MI',
	'MN',
	'MO',
	'MS',
	'MT',
	'NC',
	'ND',
	'NE',
	'NH',
	'NJ',
	'NM',
	'NV',
	'NY',
	'OH',
	'OK',
	'OR',
	'PA',
	'RI',
	'SC',
	'SD',
	'TN',
	'TX',
	'UT',
	'VA',
	'VT',
	'WA',
	'WI',
	'WV',
	'WY']
  end
  
  def year_array(num_years=10)
    years = Array.new
    
    for num in 1..num_years
      years << (Date.today.year + (num - 1))
    end
    
    years
  end
  
  def address_summary(address, show_name=true)
    return_str = ""
    
    if show_name
      return_str << (address.first_name.blank? ? "" : address.first_name)
      return_str << " "
      return_str << (address.last_name.blank? ? "" : address.last_name)
      return_str << "<br>" if !return_str.blank?
    end
    return_str << (address.address_line_1.blank? ? "" : address.address_line_1)
    if (not address.address_line_2.blank?)
      return_str << "<br>" if !return_str.blank?
      return_str << address.address_line_2
    end
    return_str << "<br>" if !return_str.blank?
    return_str << (address.city.blank? ? "" : truncate(address.city, :length => 10) + ", ")
    return_str << (address.state.blank? ? "" : address.state)
    return_str << " "
    return_str << (address.zip.blank? ? "" : address.zip)
    
    return_str
  end
  
  def address_summary_with_fedex(address, show_name=true)
    return_str = address_summary(address, show_name)
    return return_str + (address.fedex_validation_status == Address::VALID ? "" : "<br>FEDEX UNVALIDATED")
  end
  
  def addresses_for_select(addresses, selected)
    addresses_array = Array.new
    
    addresses.each do |address|
      address_str = address.first_name + " " + address.last_name + ", " + address.address_line_1
      if !address.address_line_2.blank?
        address_str << ", " + address.address_line_2
      end
      address_str << ", " + address.city + ", " + address.state + ", " + address.zip
      
      addresses_array << [address_str, address.id]
    end
    
    options_for_select(addresses_array, :selected => selected.id)
  end
  
  def vc_address
    address_summary(Address.find(Rails.application.config.fedex_vc_address_id))
  end
  
  def box_number_options(product_id)
    options = Array.new
    product = Product.find(product_id)
    
    (1..30).each do |i|
      appender = ""
      discount = Discount.new(product, i, 1)
      
      options << [i.to_s + (discount.unit_discount_perc > 0 ? " (" + number_to_percentage(discount.unit_discount_perc*100.0, :precision => 0) + ") savings" : ""), i.to_s]
    end
    
    options
  end
  
  def months_select_array
    [["01 - January", "1"], ["02 - February", "2"], ["03 - March", "3"], ["04 - April", "4"], ["05 - May", "5"], ["06 - June", "6"], ["07 - July", "7"], ["08 - August", "8"], ["09 - September", "9"], ["10 - October", "10"], ["11 - November", "11"], ["12 - December", "12"]]
  end
  
  def month_end_dates_array(near_date=Date.today)
    return_array = Array.new
    near_date = DateHelper.end_of_month(near_date)
    
    2.downto(1).each do |i|
      return_array << [DateHelper.end_of_month(near_date << i).strftime("%m/%d/%Y"), DateHelper.end_of_month(near_date << i).strftime("%m/%d/%Y")]
    end
    
    return_array << [(near_date).strftime("%m/%d/%Y"), (near_date).strftime("%m/%d/%Y")]
    
    1.upto(2).each do |i|
      return_array << [DateHelper.end_of_month(near_date >> i).strftime("%m/%d/%Y"), DateHelper.end_of_month(near_date >> i).strftime("%m/%d/%Y")]
    end
    
    return_array
  end
  
  def impersonating?
    # this is a bit of a hack, but it reflects the fact that we are overriding the current_user method in application_controller
    current_user != @current_user
  end
  
  def tracking_url(text, tracking_number)
    if text.nil? || tracking_number.nil?
      return nil
    else
      return "<a href=\"http://www.fedex.com/Tracking?action=track&tracknumbers=" + tracking_number + "\" target=\"new\">" + text + "</a>"
    end
  end
end
