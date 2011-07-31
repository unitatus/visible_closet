class OrdersController < ApplicationController
  load_and_authorize_resource
  
  # TODO: this should really get some of the site functionality. Right now it's all in account and admin.
  # GET /orders
  # GET /orders.xml
  # def index
  #   @orders = Order.all
  # 
  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.xml  { render :xml => @orders }
  #   end
  # end
  # 
  # # GET /orders/1
  # # GET /orders/1.xml
  # def show
  #   @order = Order.find(params[:id])
  # 
  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.xml  { render :xml => @order }
  #   end
  # end
  # 
  # # GET /orders/new
  # # GET /orders/new.xml
  # def new
  #   @order = Order.new
  # 
  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.xml  { render :xml => @order }
  #   end
  # end
  # 
  # # GET /orders/1/edit
  # def edit
  #   @order = Order.find(params[:id])
  # end
  # 
  # # POST /orders
  # # POST /orders.xml
  # def create
  #   @cart = Cart.find_active_by_user_id(current_user.id)
  #   @order = @cart.build_order(params[:order])
  #   @order.ip_address = request.remote_ip
  # 
  #   if @order.save
  #     if @order.purchase
  #       render :action => "success"
  #     else
  #       render :action => "failure"
  #     end
  #   else
  #     render :action => 'new'
  #   end
  # end
  # 
  # # PUT /orders/1
  # # PUT /orders/1.xml
  # def update
  #   @order = Order.find(params[:id])
  # 
  #   respond_to do |format|
  #     if @order.update_attributes(params[:order])
  #       format.html { redirect_to(@order, :notice => 'Order was successfully updated.') }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render :action => "edit" }
  #       format.xml  { render :xml => @order.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end
  # 
  # # DELETE /orders/1
  # # DELETE /orders/1.xml
  # def destroy
  #   @order = Order.find(params[:id])
  #   @order.destroy
  # 
  #   respond_to do |format|
  #     format.html { redirect_to(orders_url) }
  #     format.xml  { head :ok }
  #   end
  # end
  
  def process_order
    @order = Order.find(params[:id])
  end
  
  def ship_order_lines
    @order_lines = Array.new
  
    params[:order_line_ids].each do |order_line_id|
      order_line = OrderLine.find(order_line_id)
    
      # will save the order line
      order_line.ship
    
      @order_lines << order_line
    end
    
    # Need to create shipment for the empty boxes
    @order = Order.find(@order_lines[0].order_id)
    @order_shipment = Shipment.new
    
    @order_shipment.order_id = @order.id
    @order_shipment.from_address_id = Rails.application.config.fedex_vc_address_id
    @order_shipment.to_address_id = @order.shipping_address_id

    if !@order_shipment.save
      raise "Error saving shipment; errors: " << @order_shipment.errors.inspect
    end    
        
    if !@order_shipment.generate_fedex_label
      raise "Error generating shipment and saving; errors: " << @order_shipment.errors.inspect
    end
    
    UserMailer.shipping_materials_sent(@order.user, @order_shipment, @order_lines).deliver
  end
  
  def print_invoice
    @order = Order.find(params[:id])
    @invoice = Invoice.find_by_order_id(@order.id)
    @shipping_address = @order.shipping_address
    @vc_address = Address.find(Rails.application.config.fedex_vc_address_id)
    if @order.payment_transactions.size > 0 # only one really
      @payment_profile = @order.payment_transactions.first.payment_profile 
    else
      @payment_profile = current_user.default_payment_profile
    end

    @billing_address = @payment_profile.billing_address
    
    render :action => "print_invoice", :layout => false
  end
end
