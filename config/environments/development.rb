VisibleCloset::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Customizations for The Visible Closet
  config.our_box_product_id = 1
  config.your_box_product_id = 3
  config.our_box_inventorying_product_id = 5
  config.your_box_inventorying_product_id = 6
  
  config.s3_key = 'AKIAJZUNJU6OZH3A6VZQ'
  config.s3_secret = 'NYzFOaurfJAZk+M2TBnIy2dhRpxGrFOlDpIg8eT4'
  config.s3_path = '/public/system/photos/:access_token/:id/:style.:extension'
  config.s3_bucket = 'stored_item_photos.thevisiblecloset.com'

  config.after_initialize do
    ActiveMerchant::Billing::Base.mode = :test
    ::CIM_GATEWAY = ActiveMerchant::Billing::AuthorizeNetCimGateway.new(
      :login => "7Px7qH7p", # "API Login ID"
      :password => "974w4HTkHGMh9f9n", # "Transaction Key"
      :test => 'true' # Just delete this parameter in production
    )

    ::PURCHASE_GATEWAY = ActiveMerchant::Billing::Base.gateway(:authorize_net).new(
      :login => "7Px7qH7p", # "API Login ID"
      :password => "974w4HTkHGMh9f9n", # "Transaction Key"
      :test => 'true'
    )
  end
end

