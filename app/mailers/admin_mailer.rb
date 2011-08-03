class AdminMailer < ActionMailer::Base
  default :from => "The Visible Closet Admin <admin@thevisiblecloset.com>", :reply_to =>"admin@thevisiblecloset.com", :to => Rails.application.config.admin_email
  helper :application
  
  def interested_person_added(person)
    @interested_person = person
    
    mail(:subject => "New Interested Person")
  end
  
  def new_order(user, order, invoice, shipping_address, vc_address, payment_profile, billing_address)
    @order = order
    @user = user
    @invoice = invoice
    @shipping_address = shipping_address
    @vc_address = vc_address
    @payment_profile = payment_profile
    @billing_address = billing_address
    
    mail(:subject => "New Order")
  end
end
