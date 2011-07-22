class BoxesController < ApplicationController
  load_resource :only => [:receive_box, :inventory_box, :inventory_boxes, :clear_box, :finish_inventorying, :edit]

  authorize_resource

  require 'soap/wsdlDriver'

  def ssl_required?
    true # make every access to boxes secure
  end
  
  # GET /boxes
  # GET /boxes.xml
  def index
    @boxes = Box.find_all_by_assigned_to_user_id(current_user.id)

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
    @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)
    
    if @box.nil?
      redirect_to access_denied_url
      return
    end

    respond_to do |format|
      if @box.update_attributes(params[:box])
        @boxes = Box.find_all_by_assigned_to_user_id(current_user.id)
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
    @marked_for_indexing_locked = (params[:marked_for_indexing_locked] == "1")
    
    if params[:box_id].blank?
      return
    end
    
    begin
      box = Box.find(params[:box_id])
    rescue ActiveRecord::RecordNotFound => r
      @error_messages << "Box not found!"
      return
    end
        
    if (box.status == Box::IN_STORAGE_STATUS)
      @error_messages << ("Warning: box was in 'In Storage' status. Please record this error and see an administrator. Box id: " + box.id.to_s + ". Box was still received, but was left in this status.")
    end
    
    if (box.status == Box::NEW_STATUS)
      @error_messages << ("Warning: box was in 'New' status. Please record this error and see an administrator. Box id: " + box.id.to_s + ". Box was still received.")
    end    
    
    raise ("Error on save with box: " << box.inspect) if !box.receive(params[:marked_for_indexing] == "1" || params[:marked_for_indexing_locked] == "1")
        
    if box.indexing_status == Box::INDEXING_REQUESTED
      @error_messages << "WARNING!!! Indexing requested! Please send this box for indexing!"
    end
    
    @messages << ("Box " + box.id.to_s + " processed.")
  end  
  
  def inventory_box
    # TODO - get rid of this
    @box = Box.find(params[:id])
    @stored_items = StoredItem.find_by_box_id(@box.id)
  end
  
  def inventory_boxes
    @boxes = Box.find_all_by_indexing_status(Box::INDEXING_REQUESTED)
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
        raise "Failed to save stored tag! " << @stored_item_tag.inspect
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
    
    @box.indexing_status = Box::INDEXED
    
    @box.save!
    
    @order_line = OrderLine.find(@box.indexing_order_line_id)
    @order_line.status = OrderLine::PROCESSED_STATUS
    @order_line.save!
    
    redirect_to :controller => "admin", :action => "process_orders"
  end
  
  def get_label
    @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)
    
    if @box.nil?
      redirect_to access_denied_url
      return
    end
    
    order_line = OrderLine.find(@box.ordering_order_line_id)
    order = order_line.order
    shipping_address = Address.find(order.shipping_address_id)
    receiving_address = Address.find(Rails.application.config.fedex_vc_address_id)
    
    @fedex = Fedex::Base.new(
      :auth_key => Rails.application.config.fedex_auth_key,
      :security_code => Rails.application.config.fedex_security_code,
      :account_number => Rails.application.config.fedex_account_number,
      :meter_number => Rails.application.config.fedex_meter_number, 
      :debug => Rails.application.config.fedex_debug,
      :label_image_type => Rails.application.config.fedex_label_image_type
    )
    
    shipper = {
      :name => current_user.first_name + " " + current_user.last_name,
      :phone_number => shipping_address.day_phone
    }
    recipient = {
      :name => Rails.application.config.fedex_vc_name,
      :phone_number => receiving_address.day_phone
    }
    origin = {
      :street => shipping_address.address_line_1 + (shipping_address.address_line_2.nil? ? "" : " " + shipping_address.address_line_2),
      :city => shipping_address.city,
      :state => shipping_address.state,
      :zip => shipping_address.zip,
      :country => shipping_address.country
    }
   destination = {
     :street => receiving_address.address_line_1 + (receiving_address.address_line_2.nil? ? "" : " " + receiving_address.address_line_2),
     :city => receiving_address.city,
     :state => receiving_address.state,
    :zip => receiving_address.zip,
    :country => receiving_address.country,
    :residential => false
   }
   pkg_count = 1
   weight = Rails.application.config.fedex_default_shipping_weight_lbs
   service_type = Fedex::ServiceTypes::FEDEX_GROUND
   
   @label, @tracking_number = @fedex.label(
     :shipper => { :contact => shipper, :address => origin },
     :recipient => { :contact => recipient, :address => destination },
     :count => pkg_count,
     :weight => weight,
     :service_type => service_type
    )

    shipment = Shipment.new
    
    shipment.box_id = @box.id
    shipment.from_address_id = shipping_address.id
    shipment.to_address_id = receiving_address.id
    shipment.tracking_number = @tracking_number
    
    if (!shipment.save)
      raise "Malformed data: cannot save shipment " << shipment.inspect
    end

    send_data(@label, :filename => "box_#{@box.id}_label.pdf", :type => "application/pdf")
  end
end
