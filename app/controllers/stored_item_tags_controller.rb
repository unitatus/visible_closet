class StoredItemTagsController < ApplicationController
  authorize_resource
  
  def ssl_required?
    true
  end
  
  def delete
    @stored_item_tag = StoredItemTag.find(params[:id])

    @stored_item_tag.destroy

    respond_to do |format|
      format.js
    end
  end
  
  def add_tag
    @stored_item_tag = StoredItemTag.new

    if (!params[:tag].blank?)    
      @stored_item_tag.stored_item_id = params[:stored_item_id]
      @stored_item_tag.tag = params[:tag]
    
      if (!@stored_item_tag.save)
        raise "Failed to save stored tag! Errors: " << @stored_item_tag.errors
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
end