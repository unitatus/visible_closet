class UserMailer < ActionMailer::Base
  default :from => "The Visible Closet <shipping@thevisiblecloset.com>", :reply_to =>"shipping@thevisiblecloset.com"
  helper :application
  layout 'user_mailer', :except => :invoice_email
  
  def deliver_invoice_email(user, invoice, send_admin=false)
    if user.not_test_user?
      invoice_email(user, invoice, send_admin).deliver
    end
  end
  
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
      mail(:to => user.email, :subject => "Invoice from The Visible Closet")
      AdminMailer.deliver_new_order(@user, @order, @invoice, @vc_address, @payment_profile, @billing_address)
    end
  end
  
  def deliver_boxes_sent(user, order_lines)
    if user.not_test_user?
      invoice_email(user, order_lines).deliver
    end
  end
  
  def boxes_sent(user, order_lines)
    @user = user
    @order_lines = order_lines
    mail(:to => user.email, :subject => "Notification from The Visible Closet")
  end
  
  def deliver_box_received(box)
    if box.user.not_test_user?
      invoice_email(user, order_lines).deliver
    end
  end
  
  def box_received(box)
    @box = box
    mail(:to => box.user.email, :subject => "Notification from The Visible Closet")
  end
  
  def deliver_box_inventoried(box)
    if box.user.not_test_user?
      invoice_email(user, order_lines).deliver
    end
  end
  
  def box_inventoried(box)
    @box = box
    mail(:to => box.user.email, :subject => "Notification from The Visible Closet")
  end
end
