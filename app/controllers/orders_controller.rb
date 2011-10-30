class OrdersController < ApplicationController
  authorize_resource

  def ssl_required?
    true
  end
  
  def process_order
    @order = Order.find(params[:id])
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
