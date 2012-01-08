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
        new_subscription = Subscription.new(:duration_in_months => params[:duration], :user_id => @furniture_item.user_id)
        new_subscription.save
        @furniture_item.subscriptions << new_subscription
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
    furniture_item.update_attribute(:status, StoredItem::IN_STORAGE_STATUS)
    redirect_to "/admin/users/#{furniture_item.user_id}/furniture"
  end
  
  def admin_unpublish_furniture_item
    furniture_item = FurnitureItem.find(params[:id])
    furniture_item.update_attribute(:status, FurnitureItem::INCOMPLETE_STATUS)
    redirect_to "/admin/users/#{furniture_item.user_id}/furniture"
  end
  
  def save_photo
    furniture_item = FurnitureItem.find(params[:furniture_item_id])
    photo = StoredItemPhoto.find(params[:photo_id])
    
    puts "Updating photo #{photo.id} to visibility #{params[:visibility]}"
    photo.update_attribute(:visibility, params[:visibility]) if params[:visibility]
    
    puts "Default is #{params[:default]}"
    if params[:default].blank?
      puts "removing default photo"
      furniture_item.remove_default(photo)
    else
      puts "setting furniture item default photo at visibility #{photo.visibility}"
      furniture_item.set_default(photo)
    end
    
    redirect_to "/admin/furniture_items/#{furniture_item.id}/photos"
  end
  
  def admin_view
    @furniture_item = FurnitureItem.find(params[:id])
  end
end