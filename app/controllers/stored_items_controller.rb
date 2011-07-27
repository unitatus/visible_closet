class StoredItemsController < ApplicationController
  authorize_resource
  
  def ssl_required?
    true
  end
  
  def index
    @top_menu_page = :account
    @stored_items = StoredItem.find_all_by_assigned_to_user_id(current_user.id, params[:box_id])
  end
end