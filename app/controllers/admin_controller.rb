class AdminController < ApplicationController
  authorize_resource :class => false

  def ssl_required?
    true
  end

  def home

  end
  
  def double_post
    
  end

  def shipping
    order_lines = OrderLine.find_all_by_status_and_product_id(OrderLine::NEW_STATUS, Rails.application.config.our_box_product_id)
            
    @orders = get_orders(order_lines)
    
    @shipments = Shipment.all(:conditions => "state = 'active' or state = 'delivered'", :order => "created_at DESC")
    
    # set for navigation
    @admin_page = :shipping
        
    render 'process_orders'
  end
  
  def process_orders
    order_lines = OrderLine.find_all_by_status(OrderLine::NEW_STATUS)
    # set for navigation
    @admin_page = :orders
    
    @orders = get_orders(order_lines)
  end
  
  def users
    @admin_page = :users
    order_by = params[:sort_by]
    
    if order_by && order_by != "id"
      order_by = "LOWER(" + order_by + ")"
    end
    
    if params[:desc] && order_by
      order_by += " DESC"
    end
    
    if order_by.blank?
      @users = User.find(:all, :order => "last_name ASC")
    else
      @users = User.find(:all, :order => order_by)
    end
  end
  
  def user
    @admin_page = :users
    @user = User.find(params[:id])
  end
  
  def switch_test_user_status
    @user = User.find(params[:id])
    @user.update_attribute(:test_user, !user.test_user?)
    
    redirect_to "/admin/user/#{@user.id}"
  end
  
  def clear_user_data
    @user = User.find(params[:id])
    
    @user.clear_test_data
    
    redirect_to "/admin/users"
  end
  
  def destroy_user
    @user = User.find(params[:id])
    @user.destroy
    
    redirect_to "/admin/users"
  end
  
  def user_orders
    @admin_page = :users
    @user = User.find(params[:id])
    
    order_by = params[:sort_by]
        
    if params[:desc] && order_by
      order_by += " DESC"
    end
    
    @orders = Order.find_all_by_user_id(@user.id, :order => order_by.blank? ? "created_at DESC" : order_by)
  end
  
  def user_boxes
    @admin_page = :users
    @user = User.find(params[:id])
    
    order_by = params[:sort_by]
        
    if params[:desc] && order_by
      order_by += " DESC"
    end
    
    @boxes = Box.find_all_by_assigned_to_user_id(@user.id, :order => order_by.blank? ? "created_at DESC" : order_by)
  end
  
  def user_billing
    @admin_page = :users
    @user = User.find(params[:id])
    @transactions = @user.transaction_history
  end
  
  def user_subscription
    @admin_page = :users
    @subscription = Subscription.find_by_id_and_user_id(params[:subscription_id], params[:user_id])
  end
  
  def user_shipments
    @admin_page = :users
    @user = User.find(params[:id])
    @shipments = @user.shipments
  end
  
  def user_box
    @admin_page = :users
    @user = User.find(params[:user_id])
    @box = Box.find_by_assigned_to_user_id_and_id(params[:user_id], params[:box_id])
  end
  
  def user_order
    @admin_page = :users
    @user = User.find(params[:user_id])
    @order = Order.find_by_user_id_and_id(params[:user_id], params[:order_id])
  end
  
  def user_account_balances
    @admin_page = :monthly_charges
    @users = User.all
  end
  
  def set_shipment_charge
    @admin_page = :users
    @shipment = Shipment.find(params[:id])
    amount = params[:amount]
    
    if amount.blank?
      @error_message = "Please specify a charge."
    else
      @shipment.set_charge(amount.to_f)
    end
    
    render :shipment
  end
  
  def delete_user_order
    order = Order.find_by_user_id_and_id(params[:user_id], params[:order_id])
    order.destroy_test_order!
    
    redirect_to "/admin/user/#{params[:user_id]}/orders"
  end
  
  def delete_user_box
    box = Box.find_by_assigned_to_user_id_and_id(params[:user_id], params[:box_id])
    box.destroy
    
    params[:id] = params[:user_id]
    
    user_boxes
    
    redirect_to "/admin/user/#{params[:user_id]}/boxes"
  end
  
  def destroy_billing_charge
    charge = Charge.find(params[:id])
    @user = charge.user

    charge.destroy
    
    redirect_to "/admin/user/#{@user.id}/billing"
  end
  
  def destroy_billing_credit
    credit = Credit.find(params[:id])
    @user = credit.user
    
    credit.destroy
    
    redirect_to "/admin/user/#{@user.id}/billing"
  end
  
  def delete_shipment
    shipment = Shipment.find(params[:id])
    shipment.destroy
    
    redirect_to :action => :shipping
  end
  
  def delete_user_shipment
    shipment = Shipment.find(params[:shipment_id])
    shipment.destroy
    
    redirect_to :action => :user_shipments
  end
  
  def shipment
    @shipment = Shipment.find(params[:id])
  end
  
  def refresh_shipment_events
    @shipment = Shipment.find(params[:id])
    
    @shipment.refresh_fedex_events
    
    redirect_to :action => :shipment
  end
  
  def monthly_charges
    @admin_page = :monthly_charges
    @last_storage_charge_action = StorageChargeProcessingRecord.last
    @last_storage_payment_action = StoragePaymentProcessingRecord.last
  end
  
  def generate_charges
    as_of_date = Date.strptime(params[:as_of_date], '%m/%d/%Y')
    user = current_user
    
    record = user.storage_charge_processing_records.build(:as_of_date => as_of_date)
    record.generated_by = current_user
    
    User.all.each do |user|
      charges = user.calculate_subscription_charges(as_of_date, false, true)
      if !charges.empty?
        record.storage_charges << charges.collect {|charge| charge.storage_charge}
      end
    end
    
    record.save
    
    redirect_to "/storage_charge_processing_records/#{record.id}"
  end
  
  def generate_payments
    user = current_user
    
    @record = user.storage_payment_processing_records.build(:as_of_date => Date.today)
    @record.generated_by = current_user
    
    User.transaction do
      User.all.each do |user|
        payment = user.pay_off_account_balance_and_save
        if payment
          @record.payment_transactions << payment
        end
      end
      
      charge_records = StorageChargeProcessingRecord.all.select {|record| ! record.locked_for_editing? }
      charge_records.each do |charge_record|
        charge_record.update_attribute(:locked_for_editing, true)
      end
    end # transaction
    
    @record.save
    
    redirect_to "/storage_payment_processing_records/#{@record.id}"
  end
  
  def delete_charge
    charge = Charge.find(params[:id])
    record = charge.storage_charge ? charge.storage_charge.storage_charge_processing_record : nil
    
    charge.destroy
    
    if record
      redirect_to "/storage_charge_processing_records/#{record.id}"
    else
      redirect_to "/admin/home"
    end
  end
  
  def impersonate_user
    redirect_to access_denied_url and return unless current_user.manager?
    new_user = User.find(params[:id])
    the_current_user = current_user
    redirect_to access_denied_url and return unless new_user.normal_user?
    
    the_current_user.impersonate(new_user)
    the_current_user.save
    
    redirect_to user_root_url
  end

  def stop_impersonating
    # Must use @ to get "real" user
    user = @current_user
    
    user.stop_impersonating
    user.save
    
    redirect_to "/admin/home"
  end

  def add_user_charge
    @admin_page = :users
    @user = User.find(params[:id])
    @transactions = @user.transaction_history
    @errors = Array.new
    
    @errors << check_dollar_entry(params[:new_charge_amount])
    
    if (params[:new_charge_comment].blank?)
      @errors << "Must enter comment."
    end
    
    if !@errors.empty?
      render :user_billing and return
    else
      if !@user.add_miscellaneous_charge(Float(params[:new_charge_amount]), params[:new_charge_comment], current_user)
        @errors << @user.errors
        render :user_billing and return
      else
        redirect_to "/admin/user/#{@user.id}/billing"
      end
    end
  end
  
  def add_user_credit
    @admin_page = :users
    @user = User.find(params[:id])
    @transactions = @user.transaction_history
    @errors = Array.new
    
    @errors << check_dollar_entry(params[:new_credit_amount])
    
    if (params[:new_credit_comment].blank?)
      @errors << "Must enter comment."
    end
    
    if !@errors.empty?
      render :user_billing and return
    else
      if !@user.add_miscellaneous_credit(Float(params[:new_credit_amount]), params[:new_credit_comment], current_user)
        @errors << @user.errors
        render :user_billing and return
      else
        redirect_to "/admin/user/#{@user.id}/billing"
      end
    end
  end
  
private

  def get_orders(order_lines)
    orders = Hash.new

    order_lines.each do |order_line|
      orders[order_line.order_id] = Order.find(order_line.order_id) unless orders[order_line.order_id]
    end
    
    orders.values    
  end
end
