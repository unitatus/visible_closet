class AdminController < ApplicationController

  def home

  end

  def send_boxes
    order_lines = OrderLine.find_all_by_status(OrderLine::NEW_STATUS)
            
    @orders = Hash.new
    
    order_lines.each do |order_line|
      @orders[order_line.order_id] = Order.find(order_line.order_id) unless @orders[order_line.order_id]
    end
    
    @orders = @orders.values
  end
end
