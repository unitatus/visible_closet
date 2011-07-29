class PaymentProfilesController < ApplicationController
	authorize_resource
	
	def ssl_required?
    true # make every access to boxes secure
  end
  
  def index
  end
  
  def new
    @profile = PaymentProfile.new
    @credit_card = ActiveMerchant::Billing::CreditCard.new()
    
    if not params[:source_c].blank?
      session[:source_c] = params[:source_c]
      session[:source_a] = params[:source_a]
    end
  end
  
  def create
    @credit_card = create_new_credit_card(params)
    @profile = PaymentProfile.new
    @profile.billing_address_id = params[:profile][:billing_address_id]
    
    @profile.credit_card = @credit_card
    @profile.user_id = current_user.id
    
    if @profile.save
      if params[:default] == "1"
        current_user.update_attribute(:default_payment_profile_id, @profile.id)
      end
      
      if not (session[:source_c].blank?) # we came from somewhere; return there
        session[:payment_profile_id] = @profile.id
        redirect_to :controller => session[:source_c], :action => session[:source_a]
        session[:source_c] = nil
        session[:source_a] = nil
      else
        render :action => "index"
      end
    else
      puts("Failed to save payment profile. Errors are " << @profile.errors.inspect)
      # Need to completely reset @profile, as otherwise Rails will make the form an edit form. :|
      @new_profile = PaymentProfile.new
      @new_profile.billing_address_id = @profile.billing_address_id
      @profile.errors.each do |attr, msg|
        @new_profile.errors.add(attr, msg)
      end
      @profile = @new_profile
      render :action => "new"
    end
  end
  
  def set_default
    if not params[:id].blank?
      current_user.update_attribute(:default_payment_profile_id, params[:id])
    end
    
    render :index
  end
  
  def destroy
    if current_user.default_payment_profile_id.to_s == params[:id]
      @messages = Array.new
      @messages << "Cannot delete default payment method."
      @profile = PaymentProfile.new
      @credit_card = ActiveMerchant::Billing::CreditCard.new()
      render :action => "index"
    else
      profile = PaymentProfile.find(params[:id])
      profile.update_attribute(:active, false)
      
      @profiles = current_user.payment_profiles

      if @profiles.size == 0
        @profile = PaymentProfile.new
        @credit_card = ActiveMerchant::Billing::CreditCard.new()
        render :action => "new"
      else
        render :action => "index"
      end
    end
  end
  
  private 
  
  def create_new_credit_card(params)
    cc = ActiveMerchant::Billing::CreditCard.new()
    
    cc.type = params[:type]
    cc.number = params[:number]
    cc.verification_value = params[:verification_value]
    cc.month = params[:month]
    cc.year = params[:year]
    cc.first_name = params[:first_name]
    cc.last_name = params[:last_name]
    
    cc    
  end
end