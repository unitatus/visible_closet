class StoredItemsController < ApplicationController
  authorize_resource
  
  def ssl_required?
    true
  end
  
  def index
    @top_menu_page = :account
    @stored_items = StoredItem.find_all_by_assigned_to_user_id(current_user.id, params[:box_id])
    @boxes = Box.find_all_by_assigned_to_user_id_and_inventorying_status(current_user.id, Box::INVENTORIED)
  end
  
  def view
    @stored_item = StoredItem.find_by_id_and_user_id(params[:id], current_user.id)
    render :layout => false
  end
end