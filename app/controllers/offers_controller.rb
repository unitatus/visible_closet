class OffersController < ApplicationController
  authorize_resource
  
  def index
    @admin_page = :marketing
    @offers = Offer.all
  end
  
  def new
    @admin_page = :marketing
    @offer = Offer.new
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
    
    if !params[:benefit_num_months].blank? || !params[:benefit_num_boxes].blank?
      free_storage_benefit = FreeStorageOfferBenefit.new
      free_storage_benefit.num_months = params[:benefit_num_months]
      free_storage_benefit.num_boxes = params[:benefit_num_boxes]
      @offer.benefits << free_storage_benefit
    end
    
    if !params[:benefit_num_boxes_signup].blank?
      free_signup_benefit = FreeSignupOfferBenefit.new
      free_signup_benefit.num_boxes = params[:benefit_num_boxes_signup]
      @offer.benefits << free_signup_benefit
    end
    
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

    free_storage_benefit = @offer.free_storage_benefits[0]    
    if !params[:benefit_num_months].blank? || !params[:benefit_num_months].blank?
      free_storage_benefit ||= FreeStorageOfferBenefit.new
      free_storage_benefit.num_months = params[:benefit_num_months]
      free_storage_benefit.num_boxes = params[:benefit_num_boxes]
      @offer.benefits << free_storage_benefit
    elsif free_storage_benefit
      @offer.benefits.delete(free_storage_benefit)
      free_storage_benefit.destroy
    end
    
    free_signup_benefit = @offer.free_signup_benefits[0]
    if !params[:benefit_num_boxes_signup].blank?
      free_signup_benefit ||= FreeSignupOfferBenefit.new
      free_signup_benefit.num_boxes = params[:benefit_num_boxes_signup]
      @offer.benefits << free_signup_benefit
    elsif free_signup_benefit
      @offer.benefits.delete(free_signup_benefit)
      free_signup_benefit.destroy
    end
    
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
  
  def coupons
    @offer = Offer.find(params[:id])
  end
  
  def user_offers_coupons
    @user = current_user
  end
  
  def apply_offer_code
    @user = current_user
    
    if @user.apply_offer_or_coupon_code(params[:offer_code])
      redirect_to "/view_offers"
    else
      render :user_offers_coupons
    end
  end
  
  def dissociate_offer_from_user
    user_offer = UserOffer.find(params[:id])
    user = user_offer.user
    
    if !user_offer.used?
      user_offer.destroy
    end
    
    redirect_to "/admin/user/#{user.id}"
  end
  
  def user_offer_apply_boxes
    @offer_or_coupon = UserOffer.find(params[:id])
    
    render :user_apply_boxes
  end
  
  def user_coupon_apply_boxes
    @offer_or_coupon = Coupon.find(params[:id])
    
    render :user_apply_boxes
  end
  
  def assign_boxes_to_offer
    @offer_or_coupon = UserOffer.find(params[:id])
    
    if @offer_or_coupon.assign_boxes(params[:boxes])
      redirect_to "/view_offers"
    else
      render :user_apply_boxes
    end
  end
  
  def assign_boxes_to_coupon
    @offer_or_coupon = Coupon.find(params[:id])
    
    if @offer_or_coupon.assign_boxes(params[:boxes])
      redirect_to "/view_offers"
    else
      render :user_apply_boxes
    end
  end
end