class BoxesController < ApplicationController
  load_resource :only => [:receive_box, :inventory_box, :inventory_boxes, :clear_box, :finish_inventorying, :edit]

  authorize_resource

  def ssl_required?
    true # make every access to boxes secure
  end
  
  # GET /boxes
  # GET /boxes.xml
  def index
    @top_menu_page = :account
    @boxes = Box.find_all_by_assigned_to_user_id(current_user.id, :order => "created_at ASC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @boxes }
    end
  end

  # There is no need to show the detail of a box at this time.
  # GET /boxes/1
  # GET /boxes/1.xml
  # def show
  #   @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)
  # 
  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.xml  { render :xml => @box }
  #   end
  # end

  # At this time the only way to create a box is to order one -- the new box process happens there.
  # GET /boxes/new
  # GET /boxes/new.xml
  # def new
  #     @box = Box.new
  #     @box.assigned_to_user_id = current_user.id
  # 
  #     respond_to do |format|
  #       format.html # new.html.erb
  #       format.xml  { render :xml => @box }
  #     end
  #   end

  # GET /boxes/1/edit
  def edit
    @top_menu_page = :account
    @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)
    
    if @box.nil?
      redirect_to access_denied_url
    end
  end

  # See boxes/new
  #
  # POST /boxes
  # POST /boxes.xml
  # def create
  #   @box = Box.new(params[:box])
  #   @box.assigned_to_user_id = current_user.id
  # 
  #   respond_to do |format|
  #     if @box.save
  #       format.html { redirect_to(@box, :notice => 'Box was successfully created.') }
  #       format.xml  { render :xml => @box, :status => :created, :location => @box }
  #     else
  #       format.html { render :action => "new" }
  #       format.xml  { render :xml => @box.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end

  # PUT /boxes/1
  # PUT /boxes/1.xml
  def update
    @top_menu_page = :account
    @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)
    
    if @box.nil?
      redirect_to access_denied_url
      return
    end

    respond_to do |format|
      if @box.update_attributes(params[:box])
        @boxes = Box.find_all_by_assigned_to_user_id(current_user.id, :order => "created_at ASC")
        format.html { render :action => "index" }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @box.errors, :status => :unprocessable_entity }
      end
    end
  end

  # At this time there is no need to delete a box.
  # DELETE /boxes/1
  # DELETE /boxes/1.xml
  # def destroy
  #     @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)
  #     @box.destroy
  # 
  #     respond_to do |format|
  #       format.html { redirect_to(boxes_url) }
  #       format.xml  { head :ok }
  #     end
  #   end
  
  def receive_box
    @error_messages = Array.new
    @messages = Array.new
    @marked_for_inventorying_locked = (params[:marked_for_inventorying_locked] == "1")
    
    if params[:box_id].blank?
      return
    end
    
    begin
      box = Box.find(params[:box_id])
    rescue ActiveRecord::RecordNotFound => r
      @error_messages << "Box not found!"
      return
    end
    
    if params[:weight].to_f == 0
      @error_messages << "Weight must be a positive number."
    end
    
    if box.box_type == Box::CUST_BOX_TYPE
      if params[:height].to_f == 0
        @error_messages << "Height must be a positive number."
      end
    
      if params[:width].to_f == 0
        @error_messages << "Width must be a number."
      end
    
      if params[:length].to_f == 0
        @error_messages << "Length must be a number."
      end
    end
    
    if @error_messages.size > 0
      return
    end
        
    if (box.status == Box::IN_STORAGE_STATUS)
      @error_messages << ("Warning: box was in 'In Storage' status. Please record this error and see an administrator. Box id: " + box.id.to_s + ". Box was still received, but was left in this status.")
    end
    
    if (box.status == Box::NEW_STATUS)
      @error_messages << ("Warning: box was in 'New' status. Please record this error and see an administrator. Box id: " + box.id.to_s + ". Box was still received.")
    end    
    
    box.weight = params[:weight].to_f
    
    if box.box_type == Box::CUST_BOX_TYPE
      box.width = params[:width].to_f
      box.length = params[:length].to_f
      box.height = params[:height].to_f
    end 
    
    raise ("Error on save with box: " << box.inspect) if !box.receive(params[:marked_for_inventorying] == "1" || params[:marked_for_inventorying_locked] == "1")
        
    if box.inventorying_status == Box::INVENTORYING_REQUESTED
      @error_messages << "WARNING!!! Indexing requested! Please send this box for inventorying!"
    end
    
    @messages << ("Box " + box.id.to_s + " processed.")
    
    params[:box_id] = nil
    params[:weight] = nil
    params[:length] = nil
    params[:height] = nil
    params[:width] = nil
    
    UserMailer.box_received(box).deliver
  end  
  
  def inventory_box
    # TODO - get rid of this
    @box = Box.find(params[:id])
    @stored_items = StoredItem.find_by_box_id(@box.id)
  end
  
  def inventory_boxes
    @boxes = Box.find_all_by_inventorying_status(Box::INVENTORYING_REQUESTED)
  end
  
  def create_stored_item
    @stored_item = StoredItem.new
    @stored_item.photo = params[:file] if params.has_key?(:file)
    
    @stored_item.box_id = params[:box_id]

    # detect Mime-Type (mime-type detection doesn't work in flash)
    @stored_item.photo_content_type = MIME::Types.type_for(params[:name]).to_s if params.has_key?(:name)
    @stored_item.save!
    
    respond_to :js
  end
  
  def delete_stored_item
    begin
      stored_item = StoredItem.find(params[:id])
      
      stored_item.destroy  
    rescue ActiveRecord::RecordNotFound
      # this is fine, just means we probably reloaded on delete
    end      
    
    @box = Box.find(params[:box_id])
    @stored_items = StoredItem.find_by_box_id(@box.id)
    
    render :inventory_box
  end
  
  def clear_box 
    @box = Box.find(params[:box_id])
    
    @box.stored_items.each do |stored_item|
      stored_item.destroy
    end
    
    @stored_items = Array.new
    @box.stored_items = @stored_items
    
    redirect_to "/boxes/inventory_box?id=#{@box.id}"
  end
  
  def add_tags
    if params[:stored_item_id].blank?
      @box = Box.find(params[:box_id])
      @stored_item = @box.stored_items.first
    else
      @stored_item = StoredItem.find(params[:stored_item_id])
      @box = Box.find(@stored_item.box_id)
    end
  end
  
  def add_tag
    @stored_item_tag = StoredItemTag.new

    if (!params[:tag].blank?)    
      @stored_item_tag.stored_item_id = params[:stored_item_id]
      @stored_item_tag.tag = params[:tag]
    
      if (!@stored_item_tag.save)
        raise "Failed to save stored tag! Erorrs: " << @stored_item_tag.errors
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def delete_tag
    @stored_item_tag = StoredItemTag.find(params[:id])

    @stored_item_tag.destroy

    respond_to do |format|
      format.js
    end
  end
  
  def finish_inventorying
    @box = Box.find(params[:id])
    
    @box.inventorying_status = Box::INVENTORIED
    
    @box.save!
    
    @order_line = OrderLine.find(@box.inventorying_order_line_id)
    @order_line.status = OrderLine::PROCESSED_STATUS
    @order_line.save!
    
    UserMailer.box_inventoried(@box).deliver
    
    redirect_to :controller => "admin", :action => "process_orders"
  end
  
  def get_label
    # This method can be called by an administrator, so need to account for that
    if current_user.role == User::ADMIN || current_user.role == User::MANAGER
      @box = Box.find(params[:id])
    else
      @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)
    end

    if @box.nil?
      redirect_to access_denied_url
      return
    end
    
    shipment = @box.get_or_create_shipment

    send_data(shipment.shipment_label, :filename => shipment.shipment_label_file_name_short, :type => "application/pdf")
  end
end
