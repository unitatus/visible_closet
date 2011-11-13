class StoredItemsController < ApplicationController
  authorize_resource
  autocomplete :stored_item, :tags
  
  def ssl_required?
    true
  end
  
  def index
    @top_menu_page = :account
    if params[:tags].blank? # Someone hit the page from a link -- no search necessary
      @stored_items = StoredItem.find_all_by_assigned_to_user_id(current_user.id, params[:box_id])
    elsif !params[:selected_item].blank? # someone selected a searched-for item -- show that box, and tell the page to highlight the selected item
      @selected_item = StoredItem.find(params[:selected_item])
      @stored_items = @selected_item.box.stored_items
      params[:box_id] = @selected_item.box.id.to_s
    else # someone hit enter while typing in the stored item search field -- show the results of what they selected
      @stored_items = StoredItem.tags_search(params[:tags].split, current_user, false)
      if @stored_items.size == 1 # the user probably thought they were selecting a single item, so act like they did
        @selected_item = @stored_items[0]
        @stored_items = @selected_item.box.stored_items
        params[:box_id] = @selected_item.box.id.to_s
      end
    end
    @boxes = Box.find_all_by_assigned_to_user_id_and_inventorying_status(current_user.id, Box::INVENTORIED)
    @hide_item_search = true
  end
  
  # This call is made from fancybox when viewing an individual item
  def view
    if current_user.admin? || current_user.manager?
      @stored_item = StoredItem.find(params[:id])
    else
      @stored_item = StoredItem.find_by_id_and_user_id(params[:id], current_user.id)
    end
    
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  # This is an override of the generated method
  def autocomplete_stored_item_tags
    tag_array = params[:term].split(" ")
    items = StoredItem.tags_search(tag_array, current_user, true)
    
    # There is a helper method in the autocomplete gem called "json_for_autocomplete", but we want to format things differently
    json_ready_hash = items.collect do |item|
      {"id" => item[:id].to_s, "label" => construct_json_label(item, tag_array), "value" => item[:tag_matches].downcase }
    end
    
    # This is a bit of a hack -- we happen to know what JSON encoder the autocomplete gem is using, so we're using it here.
    # Why? Because the gem encapsulates both retrieval and formatting in the same general method -- no delegation that we could
    # intercept. Thus, since we've overridden the method, we must override the formattig into JSON. We are of course delegating
    # the same way the gem does, but if the gem were to change and delegate in a different way and come to expect that 
    # delegation this would break. Oh well. -DHZ
    render :json => Yajl::Encoder.encode(json_ready_hash)
  end
  
  def request_charitable_donation
    @stored_item = StoredItem.find_by_id_and_user_id(params[:id], current_user.id)
    @cart = current_user.get_or_create_cart
    
    @cart.add_donation_request_for(@stored_item)
    @cart.save
    
    respond_to do |format|
      format.js
    end
  end
  
  def cancel_donation_request
    @stored_item = StoredItem.find_by_id_and_user_id(params[:id], current_user.id)
    @cart = current_user.cart
    
    @cart.remove_donation_request(@stored_item)
    @cart.save
    
    respond_to do |format|
      format.js
    end
  end
  
  private
  
  def construct_json_label(item, tags = [])
    tag_str = item[:tag_matches].downcase
    
    tags.each do |tag|
      tag_str.gsub!(tag.downcase, "<b>#{tag.downcase}</b>")
    end
    
    return_str = "<img src='" + item[:img] + "'> " + tag_str
    
    if item[:donated]
      return_str += " (item donated to \"" + item[:donated_to].to_s + "\")"
    else
      return_str += " (Box " + item[:box_num].to_s + ")"
    end
    
    return return_str
  end
end