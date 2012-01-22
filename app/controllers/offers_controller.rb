class OffersController < ApplicationController
  authorize_resource
  
  def index
    @admin_page = :marketing
    @offers = Offer.all
  end
  
  def new
    @admin_page = :marketing
    @offer = Offer.new
    @offer.benefits << FreeStorageOfferBenefit.new
  end
  
  def create
    @admin_page = :marketing
    if params[:type] == "General"
      @offer = Offer.new
    else
      @offer = CouponOffer.new
    end
    
    @offer.update_attributes(params[:offer])
    if !@offer.is_a?(CouponOffer)
      @offer.unique_identifier = nil
    end
    @offer.creator = current_user
    
    # for now we only have one potential benefit
    benefit = FreeStorageOfferBenefit.new
    benefit.num_months = params[:benefit_num_months]
    benefit.num_boxes = params[:benefit_num_boxes]
    @offer.benefits << benefit
    
    if @offer.save
      redirect_to offers_url
    else
      render :new
    end
  end
  
  def show
    @admin_page = :marketing
    @offer = Offer.find(params[:id])
  end
  
  def edit
    @admin_page = :marketing
    @offer = Offer.find(params[:id])
  end
  
  def update
    @admin_page = :marketing
    @offer = Offer.find(params[:id])
    
    @offer.update_attributes(params[:offer])
    
    benefit = @offer.benefits[0]
    benefit.num_months = params[:benefit_num_months]
    benefit.num_boxes = params[:benefit_num_boxes]
    
    if @offer.save
      redirect_to offers_url
    else
      render :edit
    end
  end
  
  def activate
    @offer = Offer.find(params[:id])
    @offer.active = true
    @offer.save
    
    redirect_to offers_url
  end
  
  def destroy
    @offer = Offer.find(params[:id])
    @offer.destroy
    
    redirect_to offers_url
  end
end