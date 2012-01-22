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
      @offer = Offer.new(params[:offer])
    else
      @offer = CouponOffer.new(params[:offer])
    end
    
    if @offer.is_a?(CouponOffer)
      @offer.unique_identifier = nil
    end
    @offer.creator = current_user
    
    # for now we only have one potential benefit
    benefit = FreeStorageOfferBenefit.new
    benefit.num_months = params[:benefit_num_months]
    benefit.num_boxes = params[:benefit_num_boxes]
    @offer.benefits << benefit
    
    # need to validate separately to sneak our extra message in there
    @offer.valid?
    if @offer.is_a?(CouponOffer) && !params[:num_coupons].blank? && !params[:num_coupons].is_number?
      @offer.errors.add(:num_coupons, "Must be a number")
    end
    
    if !@offer.errors.empty?
      render :new and return
    end
    
    if @offer.save
      if @offer.is_a?(CouponOffer)
        @offer.add_coupons(params[:num_coupons].to_i)
      end
      
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
  
  def add_coupons
    @offer = CouponOffer.find(params[:id])
    if !params[:num_coupons].blank? && params[:num_coupons].is_number?
      @offer.add_coupons(params[:num_coupons].to_i)
    end
    
    redirect_to "/offers/#{@offer.id}"
  end
  
  def destroy_coupon
    @coupon = Coupon.find(params[:id])
    @offer = @coupon.offer
    @coupon.destroy
    
    redirect_to "/offers/#{@offer.id}"
  end
end