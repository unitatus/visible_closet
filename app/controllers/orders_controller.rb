class OrdersController < ApplicationController
  authorize_resource

  def ssl_required?
    true
  end
  
  def process_order
    @order = Order.find(params[:id])
  end
  
  def process_item_mailing_order_lines
    @order = Order.find(params[:id])
    
    # Need to create the list of addresses, even if the current selected address was deactivated subequently by the user
    @addresses = @order.user.addresses
    
    @order.order_lines.each do |order_line|
      if order_line.item_mailing? && !@addresses.include?(order_line.shipping_address)
        @addresses << order_line.shipping_address
      end
    end
  end
  
  def price_item_mailing_order_lines
    @order = Order.find(params[:id])

    @selected_order_lines = Hash.new
    
    @errors = Array.new
    
    if params[:order_line_ids].blank?
      @errors << "Please select at least one order line to which to apply this charge."
    else
      params[:order_line_ids].each do |order_line_id|
        @selected_order_lines[order_line_id] = true
      end
    end
    
    if params[:box_weight].blank?
      @errors << "Please enter a box weight."
    end

    if params[:box_height].blank?
      @errors << "Please enter a box height."
    end

    if params[:box_width].blank?
      @errors << "Please enter a box width."
    end

    if params[:box_length].blank?
      @errors << "Please enter a box length."
    end
    
    order_lines = params[:order_line_ids].blank? ? Array.new : OrderLine.find(params[:order_line_ids])
    
    # save the suggested addresses
    order_lines.each do |order_line|
      new_address_id = params[("order_line_" + order_line.id.to_s + "_address").to_sym]
      if new_address_id && new_address_id.to_i != order_line.shipping_address_id
        order_line.shipping_address = Address.find(new_address_id)
        order_line.save
      end
    end
    
    last_address_id = nil
    mismatch = false
    order_lines.each do |order_line|
      if last_address_id.nil?
        last_address_id = order_line.shipping_address_id
      else
        if last_address_id != order_line.shipping_address_id
          mismatch = true
        end
      end
    end
    
    if mismatch
      @errors << "Please only select order lines that have the same shipping address."
    end
    
    if !@errors.empty?
      flash[:notice] = "Please correct the following errors:"
    else
      packages = [{:height => params[:box_height].to_f, :width => params[:box_width].to_f, :length => params[:box_length].to_f, :weight => params[:box_weight].to_f}]
      address_package_mapping = [{:from_address => Address.find(Rails.application.config.fedex_vc_address_id), :to_address => order_lines[0].shipping_address, :packages => packages}]

      begin
        @proposed_shipping_charge = Shipment.get_shipping_prices(address_package_mapping).first[:shipping_price]
      rescue Fedex::FedexError => e
        flash[:notice] = "There were errors:"
        @errors << "Unable to retrieve shipping price from FedEx. Something is seriously wrong. You need to validate the address with the user and either correct it in the system and re-attempt this page, or use the fedex website to get the shipping price and manually enter it below."
        @proposed_shipping_charge = "ENTER MANUALLY"
      end
    end

    render :process_item_mailing_order_lines and return
  end
  
  def ship_item_mailing_order_lines
    @order = Order.find(params[:id])
    @selected_order_lines = Hash.new
    @proposed_shipping_charge = params[:proposed_shipping_charge]
    
    @errors = Array.new
    
    if params[:order_line_ids].blank?
      @errors << "Please select at least one order line to which to apply this charge."
    else
      params[:order_line_ids].each do |order_line_id|
        @selected_order_lines[order_line_id] = true
      end
    end
    
    if params[:proposed_shipping_charge].blank? || !params[:proposed_shipping_charge].is_number?
      @errors << "Please enter a numeric shipping charge."
    end
    
    if !@errors.empty?
      flash[:notice] = "Please correct the following errors:"
      render :process_item_mailing_order_lines and return
    end
    
    @order_lines = OrderLine.find(params[:order_line_ids])

    # If we already have a shipping charge then this means the user hit refresh. Deal with that gracefully.
    if @order_lines.first.item_mail_shipping_charge.nil?
      new_charge, payment_message = @order.process_mailing_order_lines(params[:proposed_shipping_charge], @order_lines, params[:charge_comment])
    
      if new_charge.nil?
        @errors << "Customer credit card was declined or otherwise failed. Credit card message: " + payment_message
        flash[:notice] = "There were errors: "
        render :new_shipping_charge and return
      end
    end
    
    render :ship_order_lines
  end
  
  def ship_order_lines
    @order = Order.find(params[:order_id])

    if params[:order_line_ids].blank?
      render :process_order
      return
    elsif OrderLine.find(params[:order_line_ids][0]).status == OrderLine::PROCESSED_STATUS # user hit refresh
      @order_lines = OrderLine.find(params[:order_line_ids])
      return
    elsif missing_charity?(params[:order_line_ids])
      flash[:notice] = "You must enter charity information if you are going to process a donation line."
      render :process_order and return
    end
    
    # Convert the passed charity information into a hash
    charities = Hash.new
    params[:order_line_ids].each do |order_line_id|
      charities[order_line_id.to_i] = params[("charity_" + order_line_id.to_s).to_sym]
    end

    @order_lines = @order.process_order_lines(params[:order_line_ids], charities)
  end
  
  def show
    @order = Order.find_by_id_and_user_id(params[:id], current_user.id)
  end
  
  def print_invoice
    @order = Order.find_by_id_and_user_id(params[:id], current_user.id)
    @invoice = @order.latest_invoice
    do_show_invoice(@invoice)
  end
  
  # only for administrators
  def show_invoice
    @invoice = Invoice.find(params[:id])
    do_show_invoice(@invoice)
  end
  
  private
  
  def missing_charity?(order_line_ids)
    order_line_ids.each do |order_line_id|
      order_line = OrderLine.find(order_line_id)
      if order_line.product.donation? && params[("charity_" + order_line.id.to_s).to_sym].blank?
        return true
      end
    end
    
    return false
  end
  
  def do_show_invoice(invoice)
    @order = invoice.order
    @vc_address = Address.find(Rails.application.config.fedex_vc_address_id)
    if @order.payment_transactions.size > 0 # only one really
      @payment_profile = @order.payment_transactions.first.payment_profile 
    else
      @payment_profile = @order.user.default_payment_profile
    end

    @billing_address = @payment_profile.billing_address
    
    render :action => "print_invoice", :layout => false
  end
end
