class MarketingController < ApplicationController
  authorize_resource :class => false
  
  def offers
    @admin_page = :marketing
    @offers = Offer.all
  end
end