class BoxesController < ApplicationController
  # GET /boxes
  # GET /boxes.xml
  def index
    @boxes = Box.find_all_by_assigned_to_user_id(current_user.id)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @boxes }
    end
  end

  # GET /boxes/1
  # GET /boxes/1.xml
  def show
    @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @box }
    end
  end

  # GET /boxes/new
  # GET /boxes/new.xml
  def new
    @box = Box.new
    @box.assigned_to_user_id = current_user.id

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @box }
    end
  end

  # GET /boxes/1/edit
  def edit
    @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)    
  end

  # POST /boxes
  # POST /boxes.xml
  def create
    @box = Box.new(params[:box])
    @box.assigned_to_user_id = current_user.id

    respond_to do |format|
      if @box.save
        format.html { redirect_to(@box, :notice => 'Box was successfully created.') }
        format.xml  { render :xml => @box, :status => :created, :location => @box }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @box.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /boxes/1
  # PUT /boxes/1.xml
  def update
    @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)

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

  # DELETE /boxes/1
  # DELETE /boxes/1.xml
  def destroy
    @box = Box.find_by_id_and_assigned_to_user_id(params[:id], current_user.id)
    @box.destroy

    respond_to do |format|
      format.html { redirect_to(boxes_url) }
      format.xml  { head :ok }
    end
  end
  
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
    
  end
end
