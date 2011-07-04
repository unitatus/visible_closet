class AddressesController < ApplicationController
  # GET /addresses
  # GET /addresses.xml
  def index
    @addresses = Address.find_active(current_user.id, :order => :first_name)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @addresses }
    end
  end

  # GET /boxes/1
  # GET /boxes/1.xml
  def show
    @address = Address.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @address }
    end
  end
  
  # GET /addresses/new
  # GET /addresses/new.xml
  def new
    @address = Address.new
    @address.user_id = current_user.id

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @address }
    end
  end

  # GET /addresses/1/edit
  def edit
    @address = Address.find_by_id_and_user_id(params[:id], current_user.id)
  end

  # POST /addresses
  # POST /addresses.xml
  def create
    @address = Address.new(params[:address])
    @address.user_id = current_user.id

    respond_to do |format|
      if @address.save
        format.html { redirect_to(addresses_url) }
        format.xml  { render :xml => @address, :status => :created, :location => @address }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @address.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /addresses/1
  # PUT /addresses/1.xml
  def update
    @address = Address.find_by_id_and_user_id(params[:id], current_user.id)

    respond_to do |format|
      if @address.update_attributes(params[:address])
        format.html { redirect_to(addresses_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @address.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /addresses/1
  # DELETE /addresses/1.xml
  def destroy
    @address = Address.find_by_id_and_user_id(params[:id], current_user.id)
    @address.status = 'inactive'
    @address.save

    respond_to do |format|
        format.html { redirect_to(addresses_url) }
        format.xml  { head :ok }
    end
  end
end
