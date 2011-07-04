module ApplicationHelper
  def error_messages_for_attribute(object, attribute)
    if (object.kind_of? ActiveRecord::Base)
      error_messages = object.errors[attribute]
    else # assume validatable for now
      error_messages = object.errors.raw(attribute)
    end

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
end
