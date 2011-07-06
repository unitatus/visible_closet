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

  def send_boxes_search

  end

  # TODO: I don't think this is used anymore. Cut?
  def send_boxes_user_search
    conditions = Array.new 
    condition_count = 0
    condition_string = ''

    if (!params[:user][:id].empty?)
      condition_count = condition_count + 1
      condition_string = 'ID = ?'
      conditions[condition_count] = params[:user][:id]
    end

    if (!params[:user][:first_name].empty?)
      if (condition_count > 0)
        condition_string << " OR "
      end
      condition_count = condition_count + 1
      condition_string << 'first_name LIKE ?'
      conditions[condition_count] = params[:user][:first_name]
    end

    if (!params[:user][:last_name].empty?)
      if (condition_count > 0)
        condition_string << " OR "
      end
      condition_count = condition_count + 1
      condition_string << 'last_name LIKE ?'
      conditions[condition_count] = params[:user][:last_name]
    end

    conditions[0] = condition_string
    @found_users = User.all(:conditions => conditions, :order => 'last_name ASC')
  end
end
