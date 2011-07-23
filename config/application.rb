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
    config.filter_parameters += [:card_number]
    config.filter_parameters += [:card_verification_value]
    config.filter_parameters += [:card_month]
    config.filter_parameters += [:card_year]
    
    config.fedex_auth_key = 'USPNgfkiu1RuPm4j'
    config.fedex_security_code = 'LmMpuDePYA9Hv8dvrBXJiIUe8'
    config.fedex_account_number = '510087720'
    config.fedex_meter_number = '118543679'
    config.fedex_debug = true
    config.fedex_label_image_type = 'PDF'
    config.fedex_vc_name = 'The Visible Closet'
    config.fedex_default_shipping_weight_lbs = 10

    # Indicate the log-in and sign-up screens that need to be SSL-required
    config.to_prepare { Devise::SessionsController.ssl_required :new, :create }
  end
end
