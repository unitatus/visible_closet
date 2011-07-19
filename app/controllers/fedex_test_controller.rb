class FedexTestController < ApplicationController
  skip_authorization_check
  
  # require 'active_shipping'
  require 'soap/wsdlDriver'
  # include ActiveMerchant::Shipping
  
  # require 'wsdl/parser'
  # require 'wsdl/importer'
  # require 'xsd/qname'
  # require 'xsd/codegen/gensupport'
  # require 'soap/mapping/wsdlencodedregistry'
  # require 'soap/mapping/wsdlliteralregistry'
  # require 'soap/rpc/driver'
  # require 'wsdl/soap/methodDefCreator'
  # require 'wsdl/soap/classDefCreatorSupport'
  # require 'wsdl/soap/classNameCreator'
    

  #   require 'wsdl/data'
  #   require 'wsdl/xmlSchema/data'
     
      # require 'wsdl/import'

      #require 'wsdl/importer'
      
       #require 'wsdl/xmlSchema/importer'
        #        
        # require 'soap/httpconfigloader'
        
       # require 'soap/property' ###### I think this is the root of the evil
        
        # require 'wsdl/xmlSchema/parser'
        

    
  def test
       
        @fedex = Fedex::Base.new(
          :auth_key => 'USPNgfkiu1RuPm4j',
          :security_code => 'LmMpuDePYA9Hv8dvrBXJiIUe8',
          :account_number => '510087720',
          :meter_number => '118543679', 
          :debug => true,
          :label_image_type => 'PDF'
        )
        
        shipper = {
          :name => "Your Name",
          :phone_number => '5205551212'
        }
        recipient = {
          :name => "Fedex",
          :phone_number => '9013693600'
        }
        origin = {
          :street => '80 E. Rio Salado Pkwy. #711', # Off Madison Ave
          :city => 'Tempe',
          :state => 'AZ',
          :zip => '85281',
          :country => 'US'
        }
       destination = {
         :street => '942 South Shady Grove Road',  # Fedex
         :city => 'Memphis',
         :state => 'TN',
        :zip => '38120',
        :country => 'US',
        :residential => false
       }
       pkg_count = 1
       weight = 10
       service_type = Fedex::ServiceTypes::FEDEX_GROUND
       
       begin
    @price, @label, @tracking_number = @fedex.label(
         :shipper => { :contact => shipper, :address => origin },
         :recipient => { :contact => recipient, :address => destination },
         :count => pkg_count,
         :weight => weight,
         :service_type => service_type
        )
      rescue => e
        puts e.backtrace
      end
    
   send_data(@label, :filename => "yourlabel.pdf", :type => "application/pdf")
    
    # @price = @fedex.price(
    #   :shipper => { :contact => shipper, :address => origin },
    #   :recipient => { :contact => recipient, :address => destination },
    #   :count => pkg_count,
    #   :weight => weight,
    #   :service_type => service_type
    # )
    
  end
  
  def test2  
    # Package up a poster and a Wii for your nephew.
    packages = [
      Package.new(  100,                        # 100 grams
                    [93,10],                    # 93 cm long, 10 cm diameter
                    :cylinder => true),         # cylinders have different volume calculations

      Package.new(  (7.5 * 16),                 # 7.5 lbs, times 16 oz/lb.
                    [15, 10, 4.5],              # 15x10x4.5 inches
                    :units => :imperial)        # not grams, not centimetres
    ]
    
    # You live in Beverly Hills, he lives in Ottawa
    origin = Location.new(      :country => 'US',
                                :state => 'CA',
                                :city => 'Beverly Hills',
                                :zip => '90210')

    destination = Location.new( :country => 'CA',
                                :province => 'ON',
                                :city => 'Ottawa',
                                :postal_code => 'K1P 1J1')
                                
    # Find out how much it'll be.
    fedex = FedEx.new(:account => '510087720', :login => '118543679', :password => 'LmMpuDePYA9Hv8dvrBXJiIUe8', :key => 'USPNgfkiu1RuPm4j')
    @response = fedex.find_rates(origin, destination, packages)
  end
end
