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
      return_str << (address.first_name.nil? ? "" : address.first_name)
      return_str << " "
      return_str << (address.last_name.nil? ? "" : address.last_name)
      return_str << "<br>"
    end
    return_str << (address.address_line_1.nil? ? "" : address.address_line_1)
    if (not address.address_line_2.blank?)
      return_str << "<br>"
      return_str << address.address_line_2
    end
    return_str << "<br>"
    return_str << (address.city.nil? ? "" : address.city)
    return_str << ", "
    return_str << (address.state.nil? ? "" : address.state)
    return_str << " "
    return_str << (address.zip.nil? ? "" : address.zip)
    
    return_str
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
end
