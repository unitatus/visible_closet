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

    if params[:order_line_ids].empty?
      render :process_order
      return
    elsif OrderLine.find(params[:order_line_ids][0]).status == OrderLine::PROCESSED_STATUS # user hit refresh
      redirect_to "/admin/double_post" and return
    end

    @order_lines, @order_shipment = @order.ship_order_lines(params[:order_line_ids])
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
  
  def do_show_invoice(invoice)
    @order = invoice.order
    @shipping_address = @order.shipping_address
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
