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
end
