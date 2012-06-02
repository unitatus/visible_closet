# Copyright (c) 2007 Joseph Jaramillo
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Fedex #:nodoc:
  
  class MissingInformationError < StandardError; end #:nodoc:
  class FedexError < StandardError; end #:nodoc
  
  # Provides access to Fedex Web Services
  class Base
    
    # Defines the required parameters for various methods
    REQUIRED_OPTIONS = {
      :base        => [ :auth_key, :security_code, :account_number, :meter_number ],
      :price       => [ :shipper, :recipient, :packages ],
      :label       => [ :shipper, :recipient, :weight, :service_type ],
      :contact     => [ :name, :phone_number ],
      :address     => [ :country, :street_lines, :city, :state, :zip ],
      :ship_cancel => [ :tracking_number ],
      :validate_address => [ :address ],
      :get_tracking_events => [ :tracking_number ]
    }
    
    # Defines the relative path to the WSDL files.  Defaults assume lib/wsdl under plugin directory.
    WSDL_PATHS = {
      :rate => 'wsdl/RateService_v9.wsdl',
      :ship => 'wsdl/ShipService_v9.wsdl',
      :validate_address => 'wsdl/AddressValidationService_v2.wsdl',
      :get_tracking_events => 'wsdl/TrackService_v5.wsdl'
    }
    
    # Defines the Web Services version implemented.
    SHIP_VERSION = { :Major => 9, :Intermediate => 0, :Minor => 0, :ServiceId => 'ship' }
    RATE_VERSION = { :Major => 9, :Intermediate => 0, :Minor => 0, :ServiceId => 'crs' }
    ADDRESS_VERSION = { :Major => 2, :Intermediate => 0, :Minor => 0, :ServiceId => 'aval'}
    TRACKING_VERSION = { :Major => 5, :Intermediate => 0, :Minor => 0, :ServiceId => 'trck'}
    
    SUCCESSFUL_RESPONSES = ['SUCCESS', 'WARNING', 'NOTE'] #:nodoc:
    
    DIR = File.dirname(__FILE__)
    
    attr_accessor :auth_key,
                  :security_code,
                  :account_number,
                  :meter_number,
                  :dropoff_type,
                  :service_type,
                  :units,
                  :packaging_type,
                  :sender,
                  :debug
    
    # Initializes the Fedex::Base class, setting defaults where necessary.
    # 
    #  fedex = Fedex::Base.new(options = {})
    #
    # === Example:
    #   fedex = Fedex::Base.new(:auth_key       => AUTH_KEY,
    #                           :security_code  => SECURITY_CODE
    #                           :account_number => ACCOUNT_NUMBER,
    #                           :meter_number   => METER_NUMBER)
    #
    # === Required options for new
    #   :auth_key       - Your Fedex Authorization Key
    #   :security_code  - Your Fedex Security Code
    #   :account_number - Your Fedex Account Number
    #   :meter_number   - Your Fedex Meter Number
    #
    # === Additional options
    #   :dropoff_type       - One of Fedex::DropoffTypes.  Defaults to DropoffTypes::REGULAR_PICKUP
    #   :packaging_type     - One of Fedex::PackagingTypes.  Defaults to PackagingTypes::YOUR_PACKAGING
    #   :label_type         - One of Fedex::LabelFormatTypes.  Defaults to LabelFormatTypes::COMMON2D.  You'll only need to change this
    #                         if you're generating completely custom labels with a format of your own design.  If printing to Fedex stock
    #                         leave this alone.
    #   :label_image_type   - One of Fedex::LabelSpecificationImageTypes.  Defaults to LabelSpecificationImageTypes::PDF.
    #   :rate_request_type  - One of Fedex::RateRequestTypes.  Defaults to RateRequestTypes::ACCOUNT
    #   :payment            - One of Fedex::PaymentTypes.  Defaults to PaymentTypes::SENDER
    #   :units              - One of Fedex::WeightUnits.  Defaults to WeightUnits::LB
    #   :currency           - One of Fedex::CurrencyTypes.  Defaults to CurrencyTypes::USD
    #   :debug              - Enable or disable debug (wiredump) output.  Defaults to false.
    #   :update_emails      - array of hashes, each one containing an entry for :email_address and an entry for :type that matches EMailNotificationRecipientTypes 
    def initialize(options = {})
      check_required_options(:base, options)
      
      @auth_key           = options[:auth_key]
      @security_code      = options[:security_code]
      @account_number     = options[:account_number]
      @meter_number       = options[:meter_number]
                        
      @dropoff_type       = options[:dropoff_type]      || DropoffTypes::REGULAR_PICKUP
      @packaging_type     = options[:packaging_type]    || PackagingTypes::YOUR_PACKAGING
      @label_type         = options[:label_type]        || LabelFormatTypes::COMMON2D
      @label_image_type   = options[:label_image_type]  || LabelSpecificationImageTypes::PDF
      @rate_request_type  = options[:rate_request_type] || RateRequestTypes::LIST
      @payment_type       = options[:payment]           || PaymentTypes::SENDER
      @units              = options[:units]             || WeightUnits::LB
      @dimension_uom      = options[:dimension_uom]     || LinearUnits::IN
      @currency           = options[:currency]          || CurrencyTypes::USD
      @debug              = options[:debug]             || false
      @label_stock_type   = options[:label_stock_type]
    end
    
    # Gets a rate quote from Fedex.
    #
    #   fedex = Fedex::Base.new(options)
    #   
    #   single_price = fedex.price(
    #     :shipper => { ... },
    #     :recipient => { ... },
    #     :weight => 1,
    #     :service_type => 'STANDARD_OVERNIGHT'
    #   }
    #   single_price #=> 1315
    #
    #   multiple_prices = fedex.price(
    #     :shipper => { ... },
    #     :recipient => { ... },
    #     :weight => 1
    #   )
    #   multiple_prices #=> { 'STANDARD_OVERNIGHT' => 1315, 'PRIORITY_OVERNIGHT' => 2342, ... }
    #
    # === Required options for price
    #   :shipper              - A hash containing contact information and an address for the shipper.  (See below.)
    #   :recipient            - A hash containing contact information and an address for the recipient.  (See below.)
    #   :weight               - The total weight of the shipped package.
    #
    # === Optional options
    #   :count                - How many packages are in the shipment. Defaults to 1.
    #   :service_type         - One of Fedex::ServiceTypes. If not specified, Fedex gives you rates for all
    #                           of the available service types (and you will receive a hash of prices instead of a
    #                           single price).
    #
    # === Address format
    # The 'shipper' and 'recipient' address values should be hashes. Like this:
    #
    #  address = {
    #    :country => 'US',
    #    :street => '1600 Pennsylvania Avenue NW'
    #    :city => 'Washington',
    #    :state => 'DC',
    #    :zip => '20500'
    #  }
    def price(options = {})
      # Check overall options
      check_required_options(:price, options)
      # Check Address Options
      check_required_options(:contact, options[:shipper][:contact])
      check_required_options(:address, options[:shipper][:address])
      # Check Contact Options
      check_required_options(:contact, options[:recipient][:contact])
      check_required_options(:address, options[:recipient][:address])
      # Prepare variables
      shipper             = options[:shipper]
      recipient           = options[:recipient]
      
      shipper_contact     = shipper[:contact]
      shipper_address     = shipper[:address]
      
      recipient_contact   = recipient[:contact]
      recipient_address   = recipient[:address]
      
      service_type        = options[:service_type]
                          
      residential         = !!recipient_address[:residential]
      service_type        = resolve_service_type(service_type, residential) if service_type
      
      packages = Array.new
      packages_provided = options[:packages]
      total_weight = 0.0
      package_count = 0
      
      packages_provided.each_with_index do |package, index|
        packages << { :SequenceNumber => index + 1, :Weight => { :Units => @units, :Value => package[:weight] }, \
          :Dimensions => { :Length => package[:length], :Width => package[:width], :Height => package[:height], :Units => @dimension_uom} }
        
        package_count = index + 1

        total_weight += package[:weight]
      end
      
      # Create the driver
      driver = create_driver(:rate)
      options = common_options(RATE_VERSION).merge(
        :RequestedShipment => {
          :Shipper => {
            :Contact => {
              :PersonName => shipper_contact[:name],
              :PhoneNumber => shipper_contact[:phone_number]
            },
            :Address => {
              :CountryCode => shipper_address[:country],
              :StreetLines => shipper_address[:street_lines],
              :City => shipper_address[:city],
              :StateOrProvinceCode => shipper_address[:state],
              :PostalCode => shipper_address[:zip]
            }
          },
          :Recipient => {
            :Contact => {
              :PersonName => recipient_contact[:name],
              :PhoneNumber => recipient_contact[:phone_number]
            },
            :Address => {
              :CountryCode => recipient_address[:country],
              :StreetLines => recipient_address[:street_lines],
              :City => recipient_address[:city],
              :StateOrProvinceCode => recipient_address[:state],
              :PostalCode => recipient_address[:zip],
              :Residential => residential
            }
          },
          :ShippingChargesPayment => {
            :PaymentType => @payment_type,
            :Payor => {
              :AccountNumber => @account_number,
              :CountryCode => shipper_address[:country]
            }
          },
          :RateRequestTypes => [@rate_request_type],
          :PackageCount => package_count,
          :DropoffType => @dropoff_type,
          :ServiceType => service_type,
          :PackagingType => @packaging_type,
          :PackageDetail => RequestedPackageDetailTypes::INDIVIDUAL_PACKAGES,
          :TotalWeight => { :Units => @units, :Value => total_weight },
          :RequestedPackageLineItems => packages
        }
      )
            
      result = driver.getRates(options)
      
      extract_price = proc do |reply_detail|
        shipment_details = reply_detail.ratedShipmentDetails
        if !shipment_details.respond_to?(:each) # only one
          shipment_details = [shipment_details]
        end
        price = nil
        for shipment_detail in shipment_details
          rate_detail = shipment_detail.shipmentRateDetail
          if rate_detail.rateType == "PAYOR_ACCOUNT_PACKAGE"
            price ||= 0.0
            price += rate_detail.totalNetCharge.amount.to_f
            break
          end
        end
        if price
          return price
        else
          raise FedexError, "Couldn't find Fedex price in response!"
        end
      end

      msg = error_msg(result, false)
      if successful?(result) && msg !~ /There are no valid services available/
        reply_details = result.rateReplyDetails
        if reply_details.respond_to?(:ratedShipmentDetails)
          price = extract_price.call(reply_details)
          service_type ? price : { reply_details.serviceType => price }
        else
          reply_details.inject({}) {|h,r| h[r.serviceType] = extract_price.call(r); h }
        end
      else
        raise FedexError.new("Unable to retrieve price from Fedex: #{msg}")
      end
    end
    
    # Generate a new shipment and return associated data, including price, tracking number, and the label itself.
    #
    #  fedex = Fedex::Base.new(options)
    #  price, label, tracking_number = fedex.label(fields)
    #
    # Returns the actual price for the label, the Base64-decoded label in the format specified in Fedex::Base,
    # and the tracking_number for the shipment.
    #
    # === Required options for label
    #   :shipper      - A hash containing contact information and an address for the shipper.  (See below.)
    #   :recipient    - A hash containing contact information and an address for the recipient.  (See below.)
    #   :weight       - The total weight of the shipped package.
    #   :service_type - One of Fedex::ServiceTypes
    #
    # === Address format
    # The 'shipper' and 'recipient' address values should be hashes. Like this:
    #
    #  shipper = {:contact => {:name => 'John Doe',
    #                          :phone_number => '4805551212'},
    #             :address => address} # See "Address" for under price.
    def label(options = {})
      options = create_basic_label_request_options(options)
      driver = create_driver(:ship)
      
      result = driver.processShipment(options)
      
      successful = successful?(result)
      
      msg = error_msg(result, false)
      if successful && msg !~ /There are no valid services available/
        # pre = result.completedShipmentDetail.shipmentRating.shipmentRateDetails
        # charge didn't work at one point, haven't fixed it yet
        # charge = ((pre.class == Array ? pre[0].totalNetCharge.amount.to_f : pre.totalNetCharge.amount.to_f) * 100).to_i
        label = Base64.decode64(result.completedShipmentDetail.completedPackageDetails.label.parts.image)
        tracking_number = result.completedShipmentDetail.completedPackageDetails.trackingIds.trackingNumber
         [label, tracking_number]
      else
        raise FedexError.new("Unable to get label from Fedex: #{msg}")
      end
    end
    
    def email_label(options = {})
      label_recipient_email = options [:label_recipient_email]
      label_expiration = options[:label_expiration]
      label_hold_at_location_phone = options[:label_hold_at_location_phone]
      label_hold_at_location_contact_name = options[:label_hold_at_location_contact_name]
      label_contact_company = options[:label_contact_company]
      label_contact_email =  options[:label_contact_email]
      item_description = options[:label_description]
      hold_at_location_address = options[:hold_at_location_address]
      
      options = create_basic_label_request_options(options)
      driver = create_driver(:ship)
      
      special_services = options[:RequestedShipment][:SpecialServicesRequested].nil? ? {} : options[:RequestedShipment][:SpecialServicesRequested]
      special_services[:SpecialServiceTypes] ||= []
      special_services[:SpecialServiceTypes] += [ShipmentSpecialServiceTypes::PENDING_SHIPMENT, ShipmentSpecialServiceTypes::HOLD_AT_LOCATION]
      special_services[:PendingShipmentDetail] ||= {}
      special_services[:PendingShipmentDetail][:Type] = PendingShipmentTypes::EMAIL
      special_services[:PendingShipmentDetail][:EmailLabelDetail] ||= {}
      special_services[:PendingShipmentDetail][:EmailLabelDetail][:NotificationEMailAddress] = label_recipient_email
      special_services[:PendingShipmentDetail][:ExpirationDate] = label_expiration.to_date
      
      special_services[:HoldAtLocationDetail] ||= {}
      special_services[:HoldAtLocationDetail][:PhoneNumber] = label_hold_at_location_phone
      special_services[:HoldAtLocationDetail][:LocationContactAndAddress] ||= {}
      special_services[:HoldAtLocationDetail][:LocationContactAndAddress][:Contact] ||= {}
      special_services[:HoldAtLocationDetail][:LocationContactAndAddress][:Contact][:PersonName] = label_hold_at_location_contact_name
      special_services[:HoldAtLocationDetail][:LocationContactAndAddress][:Contact][:CompanyName] = label_contact_company
      special_services[:HoldAtLocationDetail][:LocationContactAndAddress][:Contact][:PhoneNumber] = label_hold_at_location_phone
      special_services[:HoldAtLocationDetail][:LocationContactAndAddress][:Contact][:EMailAddress] = label_contact_email
      special_services[:HoldAtLocationDetail][:LocationContactAndAddress][:Address] = hold_at_location_address
            
      options[:RequestedShipment][:SpecialServicesRequested] ||= special_services
      options[:RequestedShipment][:RequestedPackageLineItems][:ItemDescription] = item_description
            
      result = driver.createPendingShipment(options)
      
      successful = successful?(result)
      
      msg = error_msg(result, false)
      if successful && msg !~ /There are no valid services available/
        result.completedShipmentDetail.completedPackageDetails.trackingIds.trackingNumber
      else
        raise FedexError.new("Unable to get label from Fedex: #{msg}")
      end
    end
    
    # Cancel a shipment
    #
    #  fedex = Fedex::Base.new(options)
    #  result = fedex.cancel(options)
    #
    # Returns a boolean indicating whether or not the operation was successful
    #
    # === Required options for cancel
    #   :tracking_number - The Fedex-provided tracking number you wish to cancel
    def cancel(options = {})
      check_required_options(:ship_cancel, options)
      
      tracking_number = options[:tracking_number]
      
      driver = create_driver(:ship)
      
      result = driver.deleteShipment(common_options.merge(
        :TrackingId => {
          :TrackingIdType => "GROUND",
          :TrackingNumber => tracking_number
        },
        :DeletionControl => DeletionControlTypes::DELETE_ONE_PACKAGE
      ))

      return successful?(result)
    end
    
    def cancelPendingShipment(options = {})
      check_required_options(:ship_cancel, options)
      
      tracking_number = options[:tracking_number]
      
      driver = create_driver(:ship)
      
      result = driver.cancelPendingShipment(common_options.merge(
        :TrackingId => {
          :TrackingIdType => "GROUND",
          :TrackingNumber => tracking_number
        }
      ))

      return successful?(result)
    end
    
    def validate_address(options = {})
      check_required_options(:validate_address, options)
      check_required_options(:address, options[:address])
      
      time                = options[:time] || Time.now
      time                = time.to_time.iso8601 if time.is_a?(Time)
      
      address             = options[:address]
      
      residential         = !!address[:residential]
      
      driver = create_driver(:validate_address)

      result = driver.addressValidation(common_options(ADDRESS_VERSION).merge(
        :RequestTimestamp => time,
        :Options => {
          :VerifyAddresses => true,
          :ReturnParsedElements => true
        },
        :AddressesToValidate => [
            {
              :Address => {
                :CountryCode => address[:country],
                :StreetLines => address[:street_lines],
                :City => address[:city],
                :StateOrProvinceCode => address[:state],
                :PostalCode => address[:zip],
                :Residential => residential
              }
            }
        ]
      ))
      
      successful = successful?(result)
      
      msg = error_msg(result, false)
      if successful && msg !~ /There are no valid services available/
        process_address_validation_reply(result)
      else
        { :success => false, :changes_suggested => false, :messages => ["Invalid address format"] }
      end
    end
    
    # The below should work, but I don't think we will need it for The Visible Closet.
    # Note that when you request the tracking information it only gives you the latest status.
    def get_latest_tracking_event(options = {})
      check_required_options(:get_tracking_events, options)
    
      tracking_number = options[:tracking_number]
      
      driver = create_driver(:get_tracking_events)
    
      result = driver.track(common_options(TRACKING_VERSION).merge(
        :PackageIdentifier => {
          :Value => tracking_number,
          :Type => TrackIdentifierTypes::TRACKING_NUMBER_OR_DOORTAG
        }
      ))
      
      successful = successful?(result)
      
      msg = error_msg(result, false)
      if successful && msg !~ /There are no valid services available/
        process_tracking_reply(result)
      else
        puts("Requested tracking information for tracking number " + tracking_number + " but found nothing.")
        return nil
      end
    end
    
  private
    def create_basic_label_request_options(options)
      # Check overall options
      check_required_options(:label, options)
      
      # Check Address Options
      check_required_options(:contact, options[:shipper][:contact])
      check_required_options(:address, options[:shipper][:address])
      
      # Check Contact Options
      check_required_options(:contact, options[:recipient][:contact])
      check_required_options(:address, options[:recipient][:address])
      
      # Prepare variables
      shipper             = options[:shipper]
      recipient           = options[:recipient]
      
      shipper_contact     = shipper[:contact]
      shipper_address     = shipper[:address]
      
      recipient_contact   = recipient[:contact]
      recipient_address   = recipient[:address]
      
      service_type        = options[:service_type]
      count               = options[:count] || 1
      weight              = options[:weight]
      
      time                = options[:time] || Time.now
      time                = time.to_time.iso8601 if time.is_a?(Time)
      
      residential         = !!recipient_address[:residential]
      
      service_type        = resolve_service_type(service_type, residential)
      
      customer_reference  = options[:customer_reference]
      po_reference         = options[:po_reference]
      
      update_emails       = options[:update_emails]
      
      options = common_options(SHIP_VERSION).merge(
        :RequestedShipment => {
          :ShipTimestamp => time,
          :DropoffType => @dropoff_type,
          :ServiceType => service_type,
          :PackagingType => @packaging_type,
          :TotalWeight => { :Units => @units, :Value => weight },
          :PreferredCurrency => @currency,
          :Shipper => {
            :Contact => {
              :PersonName => shipper_contact[:name],
              :PhoneNumber => shipper_contact[:phone_number]
            },
            :Address => {
              :CountryCode => shipper_address[:country],
              :StreetLines => shipper_address[:street_lines],
              :City => shipper_address[:city],
              :StateOrProvinceCode => shipper_address[:state],
              :PostalCode => shipper_address[:zip]
            }
          },
          :Recipient => {
            :Contact => {
              :PersonName => recipient_contact[:name],
              :PhoneNumber => recipient_contact[:phone_number]
            },
            :Address => {
              :CountryCode => recipient_address[:country],
              :StreetLines => recipient_address[:street_lines],
              :City => recipient_address[:city],
              :StateOrProvinceCode => recipient_address[:state],
              :PostalCode => recipient_address[:zip],
              :Residential => residential
            }
          },
          :ShippingChargesPayment => {
            :PaymentType => @payment_type,
            :Payor => {
              :AccountNumber => @account_number,
              :CountryCode => shipper_address[:country]
            }
          },
          :RateRequestTypes => @rate_request_type,
          :LabelSpecification => {
            :LabelFormatType => @label_type,
            :ImageType => @label_image_type
          },
          :PackageCount => count,
          :RequestedPackageLineItems => {
            :SequenceNumber => 1,
            :Weight => { :Units => @units, :Value => weight }
          }
        }
      )
      
      if customer_reference
        options[:RequestedShipment][:RequestedPackageLineItems][:CustomerReferences] = [
            {:CustomerReferenceType => CustomerReferenceTypes::CUSTOMER_REFERENCE,
            :Value => customer_reference}
        ]
      end
      
      if po_reference
        options[:RequestedShipment][:RequestedPackageLineItems][:CustomerReferences] << {:CustomerReferenceType => CustomerReferenceTypes::P_O_NUMBER,
        :Value => po_reference}
      end
      
      if @label_stock_type
        options[:RequestedShipment][:LabelSpecification][:LabelStockType] = @label_stock_type
      end
      
      if !update_emails.nil?
        options[:RequestedShipment][:SpecialServicesRequested] = create_update_email_services(update_emails)
      end
      
      return options
    end
  
    # Options that go along with each request
    def common_options(version=SHIP_VERSION)
      {
        :WebAuthenticationDetail => { :UserCredential => { :Key => @auth_key, :Password => @security_code } },
        :ClientDetail => { :AccountNumber => @account_number, :MeterNumber => @meter_number },
        :Version => version
      }
    end
  
    def create_update_email_services(emails_array)
      return_hash = Hash.new
      
      return_hash[:SpecialServiceTypes] = [ShipmentSpecialServiceTypes::EMAIL_NOTIFICATION]
      return_hash[:EMailNotificationDetail] = {
        :Recipients => create_email_service_recipients(emails_array)
      }
      
      return_hash
    end
    
    def create_email_service_recipients(emails_array)
      return_array = Array.new
      
      emails_array.each do |email_data|
        recipient = {
          :EMailNotificationRecipientType => email_data[:type],
          :EMailAddress => email_data[:email_address],
          :NotifyOnShipment => true,
          :NotifyOnException => true,
          :NotifyOnDelivery => true,
          :Format => "HTML",
          :Localization => {
            :LanguageCode => 'EN'
          }
        }
        
        return_array << recipient
      end
      
      return_array
    end
  
    # Checks the supplied options for a given method or field and throws an exception if anything is missing
    def check_required_options(option_set_name, options = {})
      required_options = REQUIRED_OPTIONS[option_set_name]
      missing = []
      required_options.each{|option| missing << option if options[option].nil?}
      
      unless missing.empty?
        raise MissingInformationError.new("Missing #{missing.collect{|m| ":#{m}"}.join(', ')}")
      end
    end
    
    # Creates and returns a driver for the requested action
    def create_driver(name)
      path = File.expand_path(DIR + '/' + WSDL_PATHS[name])
      wsdl = SOAP::WSDLDriverFactory.new(path)
      driver = wsdl.create_rpc_driver
      # /s+(1000|0|9c9|fcc)\s+/ => ""
      driver.wiredump_dev = STDOUT if @debug
      
      driver
    end
    
    # Resolves the ground+residential discrepancy.  If a package is shipped via Fedex Ground to an address marked as residential the service type
    # must be set to ServiceTypes::GROUND_HOME_DELIVERY and not ServiceTypes::FEDEX_GROUND.
    def resolve_service_type(service_type, residential)
      if residential && (service_type == ServiceTypes::FEDEX_GROUND)
        ServiceTypes::GROUND_HOME_DELIVERY
      else
        service_type
      end
    end
    
    # Returns a boolean determining whether a request was successful.
    def successful?(result)
      if defined?(result.cancelPackageReply)
        SUCCESSFUL_RESPONSES.any? {|r| r == result.cancelPackageReply.highestSeverity }
      else
        SUCCESSFUL_RESPONSES.any? {|r| r == result.highestSeverity }
      end
    end
    
    # Returns the error message contained in the SOAP response, if one exists.
    def error_msg(result, return_nothing_if_successful=true)
      return "" if successful?(result) && return_nothing_if_successful
      notes = result.notifications
      if notes.respond_to?(:message)
        notes.message
      elsif notes.respond_to?(:first)
        notes.first.message
      else
        "No message"
      end
    end
    
    # Attempts to determine the carrier code for a tracking number based upon its length.  Currently supports Fedex Ground and Fedex Express
    def carrier_code_for_tracking_number(tracking_number)
      case tracking_number.length
      when 12
        'FDXE'
      when 15
        'FDXG'
      end
    end
    
    # Clearly, this is not yet working.
    def process_tracking_reply(request)
      Array.new
    end
    
    def process_address_validation_reply(reply)
      address_data = Hash.new

      address_data[:success] = reply.addressResults.proposedAddressDetails.deliveryPointValidation == "CONFIRMED"
      address_data[:changes_suggested] = contains(reply.addressResults.proposedAddressDetails.changes, "MODIFIED_TO_ACHIEVE_MATCH")
      address_data[:messages] = reply.addressResults.proposedAddressDetails.changes.respond_to?(:each) ? reply.addressResults.proposedAddressDetails.changes : [reply.addressResults.proposedAddressDetails.changes]
      
      parsed_address = reply.addressResults.proposedAddressDetails.parsedAddress
      
      parsed_line = elements_to_hash(parsed_address.parsedStreetLine)
      parsed_postal_code = elements_to_hash(parsed_address.respond_to?(:parsedPostalCode) ? parsed_address.parsedPostalCode : nil)
      
      address_data[:line_1] = {:suggested_value => [nil_to_s(parsed_line, :houseNumber, :value), nil_to_s(parsed_line, :leadingDirectional, :value), \
          nil_to_s(parsed_line, :streetName, :value), nil_to_s(parsed_line, :streetSuffix, :value), nil_to_s(parsed_line, :trailingDirectional, :value)].join(" ") }
      address_data[:line_2] = {:suggested_value => [nil_to_s(parsed_line, :unitLabel, :value), nil_to_s(parsed_line, :unitNumber, :value)].join(" ") }
      
      if address_data[:line_2][:suggested_value].blank?
        address_data[:line_2][:suggested_value] = ""
      end
      
      address_data[:city] = {:suggested_value => parsed_address.parsedCity.elements.value }      
      address_data[:state_or_province] = {:suggested_value => parsed_address.parsedStateOrProvinceCode.elements.value }
      address_data[:postal_code] = {:suggested_value => nil_to_s(parsed_postal_code, :postalBase, :value) + "-" + \
          nil_to_s(parsed_postal_code,:postalAddOn, :value) }
      address_data[:country_code] = {:suggested_value => parsed_address.parsedCountryCode.elements.value }
      
      address_data
    end
    
    def nil_to_s(hash, level1, level2=nil)
      if hash.nil? || hash[level1].nil?
        return ""
      elsif level2.nil?
        return hash[level1]
      else
        return hash[level1][level2]
      end
    end
    
    def contains(elements, value)
      if elements.respond_to?(:each)
        elements.each do |element|
          if element == value
            return true
          end
        end
      else
        if elements == value
          return true
        end
      end
      return false
    end
    
    def elements_to_hash(element_parent)
      parsed_hash = Hash.new
      
      if !element_parent.respond_to?(:elements)
        return nil
      else
        elements = element_parent.elements
      end
      
      if elements.respond_to?(:each)
        elements.each do |element|
          parsed_hash[element.name.to_s.to_sym] = {:value => element.value, :changed => element.changes != "NO_CHANGES"}
        end
      else
        parsed_hash[elements.name.to_s.to_sym] = {:value => elements.value, :changed => elements.changes != "NO_CHANGES"}
      end
      
      return parsed_hash
    end
  end  
end
