class StoredItemsController < ApplicationController
  def index
    if params[:box_id].blank?
      @stored_items = StoredItem.find_all_by_assigned_to_user_id(current_user.id)
    else
      @stored_items = StoredItem.find_all_by_box_id(params[:box_id])
    end
  end
end