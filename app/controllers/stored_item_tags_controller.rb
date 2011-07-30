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
end