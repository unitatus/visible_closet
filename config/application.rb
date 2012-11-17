require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module VisibleCloset
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/app/middlewares)
    config.time_zone = "Central Time (US & Canada)"

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    config.filter_parameters += [:number]
    config.filter_parameters += [:verification_value]
    config.filter_parameters += [:month]
    config.filter_parameters += [:year]
    
    # Test account
    config.fedex_auth_key = 'bHbI4jcejTh58tHK'
    config.fedex_security_code = 'Cr52GqtoTfnp48MEzaSRUP7M6'
    config.fedex_account_number = '299468437'
    config.fedex_meter_number = '103089427'
    
    # Boxes
    config.vc_box_height = 12
    config.vc_box_width = 12
    config.vc_box_length = 24
    config.volume_uom = 'cubic feet'
    config.weight_uom = 'lbs'
    config.box_dimension_uom = 'IN'
    config.box_dimension_divisor = 12.0
    
    config.fedex_debug = true
    config.fedex_customer_label_image_type = 'PDF'
    config.fedex_vc_label_image_type = 'PNG'
    config.fedex_default_shipping_weight_lbs = 10
  
    config.s3_key = 'AKIAJZUNJU6OZH3A6VZQ'
    config.s3_secret = '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'
    config.s3_photo_path = '/public/system/photos/:access_token/:id/:style.:extension'
    config.s3_photo_bucket = 'stored_item_photos'
    config.s3_labels_path = '/public/system/labels/'
    config.s3_labels_bucket = 'shipment_labels'
    
    config.admin_email = "admin@thevisiblecloset.com"
    config.shipping_email = "shipping@thevisiblecloset.com"
    config.label_expiration_days = 29
    config.label_hold_at_location_phone = "8473349547"
    config.fedex_contact_name = "Brian Van Heck"
    config.fedex_contact_company = "The Visible Closet"
    config.fedex_label_description = "Visible Closet Shipment"
    config.fedex_hold_location_address = "2518 Green Bay Rd"
    config.fedex_hold_location_city = "Evanston"
    config.fedex_hold_location_state = "IL"
    config.fedex_hold_location_zip = "60201"
    
    config.shipping_up_percent = 0.2
    
    ::CIM_GATEWAY = ActiveMerchant::Billing::AuthorizeNetCimGateway.new(
      :login => "5Fe5e8GF6z7H", # "API Login ID"
      :password => "83zM4HAnrm84D4pB" # "Transaction Key"
    )
    
    ::PURCHASE_GATEWAY = ActiveMerchant::Billing::Base.gateway(:authorize_net).new(
      :login => "5Fe5e8GF6z7H", # "API Login ID"
      :password => "83zM4HAnrm84D4pB" # "Transaction Key"
    )
  end
end
