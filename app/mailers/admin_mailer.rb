class AdminMailer < ActionMailer::Base
  default :from => "The Visible Closet Admin <admin@thevisiblecloset.com>", :reply_to =>"admin@thevisiblecloset.com", :to => Rails.application.config.admin_email
  helper :application
  
  def interested_person_added(person)
    @interested_person = person
    
    mail(:subject => "New Interested Person")
  end
  
  def new_order(user, order, invoice, vc_address, payment_profile, billing_address)
    @order = order
    @user = user
    @invoice = invoice
    @vc_address = vc_address
    @payment_profile = payment_profile
    @billing_address = billing_address
    
    mail(:subject => "New Order")
  end
  
  def contact_post(email, text, remote_ip)
    
    @text = text
    @remote_ip = remote_ip
    
    mail(:from => email, :reply_to => email, :subject => "Web user email")
  end
  
  def support_post(email, text, remote_ip, user)
    
    @text = text
    @remote_ip = remote_ip
    @user = user
    
    mail(:from => email, :reply_to => email, :subject => "Web user support email")
  end
end
