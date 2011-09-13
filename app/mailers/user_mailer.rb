class UserMailer < ActionMailer::Base
  default :from => "The Visible Closet <shipping@thevisiblecloset.com>", :reply_to =>"shipping@thevisiblecloset.com"
  helper :application
  layout 'user_mailer', :except => :invoice_email
  
  def invoice_email(user, invoice, send_admin = false)
    @user = user
    @order = invoice.order
    @invoice = invoice
    
    @vc_address = Address.find(Rails.application.config.fedex_vc_address_id)
    
    if @invoice.payment_transaction
      @payment_profile = @invoice.payment_transaction.payment_profile 
    else
      @payment_profile = @user.default_payment_profile
    end

    @billing_address = @payment_profile.billing_address
    
    if !send_admin
      mail(:to => user.email, :subject => "Invoice from The Visible Closet")
    else
      user_email = mail(:to => user.email, :subject => "Invoice from The Visible Closet")
      AdminMailer.new_order(@user, @order, @invoice, @vc_address, @payment_profile, @billing_address).deliver
      return user_email
    end
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
