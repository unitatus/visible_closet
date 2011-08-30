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
    
    @shipments = Shipment.find_all_by_state(Shipment::ACTIVE, :order => "created_at DESC")
    
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
      @users = User.all
    else
      @users = User.find(:all, :order => order_by)
    end
  end
  
  def user
    @user = User.find(params[:id])
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
    @user = User.find(params[:id])
    
    order_by = params[:sort_by]
        
    if params[:desc] && order_by
      order_by += " DESC"
    end
    
    @orders = Order.find_all_by_user_id(@user.id, :order => order_by.blank? ? "created_at DESC" : order_by)
  end
  
  def user_boxes
    @user = User.find(params[:id])
    
    order_by = params[:sort_by]
        
    if params[:desc] && order_by
      order_by += " DESC"
    end
    
    @boxes = Box.find_all_by_assigned_to_user_id(@user.id, :order => order_by.blank? ? "created_at DESC" : order_by)
  end
  
  def user_billing
    @user = User.find(params[:id])
    @transactions = @user.transaction_history
  end
  
  def user_subscription
    @subscription = Subscription.find_by_id_and_user_id(params[:subscription_id], params[:user_id])
  end
  
  def user_shipments
    @user = User.find(params[:id])
    @shipments = @user.shipments
  end
  
  def user_box
    @user = User.find(params[:user_id])
    @box = Box.find_by_assigned_to_user_id_and_id(params[:user_id], params[:box_id])
  end
  
  def user_order
    @user = User.find(params[:user_id])
    @order = Order.find_by_user_id_and_id(params[:user_id], params[:order_id])
  end
  
  def set_shipment_charge
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

private

  def get_orders(order_lines)
    orders = Hash.new

    order_lines.each do |order_line|
      orders[order_line.order_id] = Order.find(order_line.order_id) unless orders[order_line.order_id]
    end
    
    orders.values    
  end
end
