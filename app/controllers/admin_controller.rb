class AdminController < ApplicationController
  authorize_resource :class => false

  def ssl_required?
    true
  end

  def home

  end

  def shipping
    order_lines = OrderLine.find_all_by_status_and_product_id(OrderLine::NEW_STATUS, Rails.application.config.our_box_product_id)
            
    @orders = get_orders(order_lines)
    
    @shipments = Shipment.find_all_by_state(Shipment::ACTIVE)
    
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
  
  def user_orders
    @user = User.find(params[:id])
    
    order_by = params[:sort_by]
        
    if params[:desc] && order_by
      order_by += " DESC"
    end
    
    if order_by.blank?
      @orders = Order.find_all_by_user_id(@user.id, :order => "created_at DESC")
    else
      @orders = Order.find_all_by_user_id(@user.id, :order => order_by)
    end
  end
  
  def user_shipments
    @user = User.find(params[:id])
    @shipments = @user.shipments
  end
  
  def delete_user_order
    order = Order.find_by_user_id_and_id(params[:user_id], params[:order_id])
    order.destroy_test_order!
    
    params[:id] = params[:user_id]
    
    user_orders
    
    redirect_to :action => :user_orders
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
