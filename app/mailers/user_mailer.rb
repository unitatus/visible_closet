class UserMailer < ActionMailer::Base
  default :from => "The Visible Closet <shipping@thevisiblecloset.com>", :reply_to =>"shipping@thevisiblecloset.com"
  helper :application
  
  def invoice_email(user, invoice)
    @user = user
    @order = invoice.order
    @invoice = invoice
    
    if @order
      @shipping_address = @order.shipping_address
    else
      @shipping_address = user.default_shipping_address
    end
    @vc_address = Address.find(Rails.application.config.fedex_vc_address_id)
    
    if @invoice.payment_transaction
      @payment_profile = @invoice.payment_transaction.payment_profile 
    else
      @payment_profile = @user.default_payment_profile
    end

    @billing_address = @payment_profile.billing_address
    
    mail(:to => user.email, :subject => "Invoice from The Visible Closet")
  end
  
  def shipping_materials_sent(user, shipment, order_lines)
    @user = user
    @shipment = shipment
    @order_lines = order_lines
    mail(:to => user.email, :subject => "Notification from The Visible Closet")
  end
  
  def box_received(box)
    @box = box
    mail(:to => box.user.email, :subject => "Notification from The Visible Closet")
  end
  
  def box_inventoried(box)
    @box = box
    mail(:to => box.user.email, :subject => "Notification from The Visible Closet")
  end
end
