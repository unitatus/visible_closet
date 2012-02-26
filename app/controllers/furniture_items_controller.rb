class FurnitureItemsController < ApplicationController
  authorize_resource
  
  def admin_index
    @user = User.find(params[:id])
  end
  
  def admin_add
    @user = User.find(params[:id])
    @furniture_item = FurnitureItem.new
  end
  
  def admin_edit
    @furniture_item = FurnitureItem.find(params[:id])
  end
  
  def admin_create
    @user = User.find(params[:id])
    @furniture_item = @user.furniture_items.build(params[:furniture_item])
    
    @furniture_item.creator = current_user
    
    if @furniture_item.save
      if !params[:duration].blank? && params[:duration].is_number?
        @furniture_item.add_subscription(params[:duration])
      end
      
      redirect_to "/admin/furniture_items/#{@furniture_item.id}/photos"
    else
      render :admin_add
    end
  end
  
  def admin_manage_photos
    @furniture_item = FurnitureItem.find(params[:id])
  end
  
  def admin_create_photo
    @furniture_item = FurnitureItem.find(params[:id])
    @photo = @furniture_item.stored_item_photos.build
    
    @photo.photo = params[:file] if params.has_key?(:file)
    # detect Mime-Type (mime-type detection doesn't work in flash)
    @photo.photo_content_type = MIME::Types.type_for(params[:name]).to_s if params.has_key?(:name)

    @photo.save
    
    respond_to :js
  end
  
  def admin_destroy_furniture_item
    @furniture_item = FurnitureItem.find(params[:id])
    
    @furniture_item.destroy
    
    redirect_to "/admin/users/#{@furniture_item.user_id}/furniture"    
  end
  
  def admin_save
    @furniture_item = FurnitureItem.find(params[:id])
    
    @furniture_item.update_attributes(params[:furniture_item])
    
    if @furniture_item.save
      if !params[:duration].blank? && params[:duration].is_number?
        if @furniture_item.subscriptions.empty?
          new_subscription = Subscription.new(:duration_in_months => params[:duration], :user_id => @furniture_item.user_id)
          new_subscription.save
          @furniture_item.subscriptions << new_subscription
        else
          subscription = @furniture_item.subscriptions.last
          subscription.update_attribute(:duration_in_months, params[:duration])
          subscription.start_subscription
        end
      else
        @furniture_item.subscriptions.each do |subscription|
          subscription.destroy
        end
      end
      
      redirect_to "/admin/users/#{@furniture_item.user_id}/furniture"
    else
      render :admin_edit
    end
  end
  
  def admin_destroy_photo    
    begin
      stored_item_photo = StoredItemPhoto.find(params[:photo_id])

      stored_item_photo.destroy  
    rescue ActiveRecord::RecordNotFound
      # this is fine, just means we probably reloaded on delete
    end      

    @furniture_item = FurnitureItem.find(params[:furniture_item_id])

    render :admin_manage_photos
  end
  
  def admin_publish_furniture_item
    furniture_item = FurnitureItem.find(params[:id])
    furniture_item.publish
    redirect_to "/admin/users/#{furniture_item.user_id}/furniture"
  end
  
  def admin_unpublish_furniture_item
    furniture_item = FurnitureItem.find(params[:id])
    furniture_item.unpublish!
    redirect_to "/admin/users/#{furniture_item.user_id}/furniture"
  end
  
  def save_photo
    furniture_item = FurnitureItem.find(params[:furniture_item_id])
    photo = StoredItemPhoto.find(params[:photo_id])
    
    photo.update_attribute(:visibility, params[:visibility]) if params[:visibility]
    
    if params[:default].blank?
      furniture_item.remove_default(photo)
    else
      furniture_item.set_default(photo)
    end
    
    redirect_to "/admin/furniture_items/#{furniture_item.id}/photos"
  end
  
  def admin_view
    @furniture_item = FurnitureItem.find(params[:id])
  end
  
  def index
    @top_menu_page = :account
    if !params[:selected_item].blank? # someone selected a searched-for item -- show that box, and tell the page to highlight the selected item
      @selected_item = FurnitureItem.find(params[:selected_item])
      @stored_items = Array.new # makes this behave nicely with StoredItem code
      @stored_items << @selected_item
    elsif params[:tags].blank? # Someone hit the page from a link -- no search necessary
        @stored_items = FurnitureItem.find_all_by_user_id_and_status(current_user.id, [StoredItem::IN_STORAGE_STATUS, FurnitureItem::RETRIEVAL_REQUESTED])
    else # someone hit enter while typing in the stored item search field -- show the results of what they selected
      @stored_items = FurnitureItem.tags_search(params[:tags].split, current_user, false)
      if @stored_items.size == 1 # the user probably thought they were selecting a single item, so act like they did
        @selected_item = @stored_items[0]
        @stored_items = Array.new
      end
    end
    @hide_item_search = true
  end
  
  # This call is made from fancybox when viewing an individual item
  def view
    if current_user.admin? || current_user.manager?
      @stored_item = FurnitureItem.find(params[:id])
    else
      @stored_item = FurnitureItem.find_by_id_and_user_id(params[:id], current_user.id)
    end
    
    respond_to do |format|
      format.html { render :layout => false }
    end
  end
  
  def save_description
    @stored_item = FurnitureItem.find_by_id_and_user_id(params[:id], current_user.id)
    
    if @stored_item
      @stored_item.update_attribute(:description, params[:description])
    end
    
    redirect_to "/furniture_items"
  end

end