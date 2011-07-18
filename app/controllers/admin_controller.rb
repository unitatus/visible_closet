class AdminController < ApplicationController
  authorize_resource :class => false

  def home

  end

  def send_boxes
    order_lines = OrderLine.find_all_by_status_and_product_id(OrderLine::NEW_STATUS, Rails.application.config.our_box_product_id)
            
    @orders = get_orders(order_lines)
    
    render 'process_orders'
  end
  
  def process_orders
    order_lines = OrderLine.find_all_by_status(OrderLine::NEW_STATUS)
            
    @orders = get_orders(order_lines)
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
