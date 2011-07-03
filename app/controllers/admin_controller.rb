class AdminController < ApplicationController

  def home

  end

  def send_boxes

  end

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
