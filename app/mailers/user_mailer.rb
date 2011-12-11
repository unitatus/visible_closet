class UserMailer < ActionMailer::Base
  default :from => "The Visible Closet <shipping@thevisiblecloset.com>", :reply_to =>"shipping@thevisiblecloset.com"
  helper :application
  layout 'user_mailer', :except => :invoice_email
  
  def UserMailer.deliver_invoice_email(user, invoice, send_admin=false)
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
      AdminMailer.deliver_new_order(@user, @order, @invoice, @vc_address, @payment_profile, @billing_address)
      mail(:to => user.email, :subject => "Invoice from The Visible Closet")
    end
  end
  
  def UserMailer.deliver_storage_charges_paid(user, payment)
    if user.not_test_user?
      storage_charges_paid(user, payment).deliver
    end
  end
  
  def storage_charges_paid(user, payment)
    @user = user
    @payment = payment
    mail(:to => user.email, :subject => "Visible Closet Storage Charges Paid")
  end
  
  def UserMailer.deliver_storage_charge_cc_rejected(user, rejected_message)
    if user.not_test_user?
      storage_charge_cc_rejected(user, rejected_message).deliver
    end
  end
  
  def storage_charge_cc_rejected(user, rejected_message)
    @user = user
    @rejected_message = rejected_message
    mail(:to => user.email, :subject => "Visible Closet CREDIT CARD DECLINED")
  end
  
  def UserMailer.deliver_order_lines_processed(user, order_lines)
    if user.not_test_user?
      order_lines_processed(user, order_lines).deliver
    end
  end
  
  def order_lines_processed(user, order_lines)
    @user = user
    @order_lines = order_lines
    mail(:to => user.email, :subject => "Notification from The Visible Closet")
  end
  
  def UserMailer.deliver_order_line_cancelled(order_line)
    if order_line.order.user.not_test_user?
      order_line_cancelled(order_line).deliver
    end
  end
  
  def order_line_cancelled(order_line)
    @order_line = order_line
    @user = @order_line.order.user
    mail(:to => @user.email, :subject => "Notification from The Visible Closet")
  end
  
  def UserMailer.deliver_box_received(box)
    if box.user.not_test_user?
      box_received(box).deliver
    end
  end
  
  def box_received(box)
    @box = box
    mail(:to => box.user.email, :subject => "Notification from The Visible Closet")
  end
  
  def UserMailer.deliver_box_inventoried(box)
    if box.user.not_test_user?
      box_inventoried(box).deliver
    end
  end
  
  def box_inventoried(box)
    @box = box
    mail(:to => box.user.email, :subject => "Notification from The Visible Closet")
  end
end
