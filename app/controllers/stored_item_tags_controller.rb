class StoredItemTagsController < ApplicationController
  authorize_resource
  
  def ssl_required?
    true
  end
  
  def delete
    if current_user.admin? || current_user.manager?
      @stored_item_tag = StoredItemTag.find(params[:id])
    else
      @stored_item_tag = StoredItemTag.find_by_id_and_user_id(params[:id], current_user.id)
    end

    @stored_item_tag.destroy

    respond_to do |format|
      format.js
    end
  end
  
  def add_tag
    @stored_item_tag = StoredItemTag.new

    if current_user.admin? || current_user.manager?
      passed_security = true
    else
      passed_security = !StoredItem.find_by_id_and_user_id(params[:stored_item_id], current_user.id).nil?
    end

    if passed_security
      if (!params[:tag].blank?)    
        @stored_item_tag.stored_item_id = params[:stored_item_id]
        @stored_item_tag.tag = params[:tag]
    
        if (!@stored_item_tag.save)
          raise "Failed to save stored tag! Errors: " << @stored_item_tag.errors
        end
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
end