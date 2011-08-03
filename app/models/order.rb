# == Schema Information
# Schema version: 20110729155026
#
# Table name: orders
#
#  id                  :integer         not null, primary key
#  cart_id             :integer
#  ip_address          :string(255)
#  user_id             :integer
#  created_at          :datetime
#  updated_at          :datetime
#  shipping_address_id :integer
#

class Order < ActiveRecord::Base
  belongs_to :cart
  has_many :payment_transactions
  has_many :order_lines, :dependent => :destroy
  belongs_to :user
  belongs_to :shipping_address, :class_name => "Address"

  attr_accessible :user_id, :created_at

  def purchase()
    transaction_successful = false

    self.transaction do
      if (!save)
        raise ActiveRecord::Rollback
      end
      
      charges, payment_transaction = pay_for_order
      
      # If this gets a DB error an uncaught exception will be thrown, which should kill the transaction
      do_post_payment_processing(charges, payment_transaction)
      
      transaction_successful = true
    end # end transaction    

    return transaction_successful
  end

  def total_in_cents
    (cart.estimated_total*100).round
  end
  
  def build_order_line(attributes={})
    order_line = order_lines.build(:attributes => attributes)
    
    order_line.order_id = id
    
    order_line
  end
  
  def status
    status = OrderLine::PROCESSED_STATUS
    
    order_lines.each do |order_line|
      if order_line.status == OrderLine::NEW_STATUS
        status = OrderLine::NEW_STATUS
      end
    end
    
    return status
  end
  
  # this method saves the charges
  def generate_charges
    raise "Attempted to call generate charges on unsaved order" unless self.id
    charges = Array.new
    
    order_lines.each do | order_line |
      charges << Charge.create!(:user_id => user_id, :total_in_cents => order_line.total_in_cents, :product_id => order_line.product_id)
    end
    
    charges
  end
  
  def vc_box_count
    total = 0
    
    order_lines.each do |order_line|
      total += order_line.quantity if order_line.product_id == Rails.application.config.our_box_product_id
    end
    
    total
  end
  
  def cust_box_count
    total = 0
    
    order_lines.each do |order_line|
      total += order_line.quantity if order_line.product_id == Rails.application.config.your_box_product_id
    end
    
    total
  end
  
  private
  
  # This method saves the transactions
  def pay_for_order()
    charges = generate_charges

    new_transaction, message = PaymentTransaction.pay(charges, user.default_payment_profile, self.id)
    
    if new_transaction.nil?
      errors.add("cc_response", message)
      raise ActiveRecord::Rollback
    end
    
    return [charges, new_transaction]
  end

  # this method throws a RuntimeError b/c the only way that save wouldn't work is if something went really wrong
  # and we don't want to miss that.
  def do_post_payment_processing(charges, payment_transaction)
    cart.mark_ordered
    
    if (!cart.save)
      raise "Unable to save cart. Cart: " << cart.inspect
    end
    
    order_lines.each do |order_line|
      product = order_line.product
      
      if product.id.to_s == Rails.application.config.our_box_product_id.to_s
        type = Box::VC_BOX_TYPE
        status = Box::NEW_STATUS
      elsif product.id.to_s == Rails.application.config.your_box_product_id.to_s
        type = Box::CUST_BOX_TYPE
        status = Box::BEING_PREPARED_STATUS
        order_line.status = OrderLine::PROCESSED_STATUS
        order_line.save
      else
        raise "Bad configuration - no match on product " << product.inspect << ", for which product.id returned " << product.id.to_s << "."
      end

      for i in 1..(order_line.quantity)
        if !Box.create!(:assigned_to_user_id => user.id, :ordering_order_line_id => order_line.id, :status => status, :box_type => type, :indexing_status => Box::NO_INDEXING_REQUESTED)
          raise "Standard box creation failed."
        end
      end # inner for loop
    end
    
    invoice = create_invoice(charges, payment_transaction)

    UserMailer.invoice_email(user, invoice, true).deliver
  end # end function
  
  def create_invoice(charges, payment_transaction)
    invoice = Invoice.new()
    
    invoice.user = user
    invoice.payment_transaction = payment_transaction
    invoice.order = self
    
    if !invoice.save
      raise "Unable to create invoice; errors: " << invoice.errors.inspect
    end
    
    invoice
  end
end
