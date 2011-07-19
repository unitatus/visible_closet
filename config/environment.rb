# Load the rails application
require File.expand_path('../application', __FILE__)
require Rails.root.join('lib', 'add_symbolize.rb')
require Rails.root.join('lib', 'extend_symbol.rb')

# Initialize the rails application
VisibleCloset::Application.initialize!

Devise::SessionsController.ssl_required :new, :create