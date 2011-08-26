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
  has_many :payment_transactions, :dependent => :destroy
  has_many :order_lines, :dependent => :destroy
  belongs_to :user
  belongs_to :shipping_address, :class_name => "Address"
  has_many :charges, :dependent => :destroy
  has_many :shipments, :dependent => :destroy
  has_many :invoices, :dependent => :destroy

  attr_accessible :user_id, :created_at

  def purchase()
    transaction_successful = false

    self.transaction do
      if (!save)
        raise ActiveRecord::Rollback
      end
      
      if total_in_cents > 0.0
        charges, payment_transaction = pay_for_order
      end
      
      # If this gets a DB error an uncaught exception will be thrown, which should kill the transaction
      do_post_payment_processing(charges, payment_transaction)
      
      transaction_successful = true
    end # end transaction    

    return transaction_successful
  end
  
  def ship_order_lines(order_line_ids)
    @order_lines = Array.new
    
    self.transaction do
  
      order_line_ids.each do |order_line_id|
        order_line = OrderLine.find(order_line_id)
    
        # will save the order line
        order_line.ship
    
        @order_lines << order_line
      end
    
      # Need to create shipment for the empty boxes
      @order_shipment = Shipment.new
    
      @order_shipment.order_id = self.id
      @order_shipment.from_address_id = Rails.application.config.fedex_vc_address_id
      @order_shipment.to_address_id = self.shipping_address_id

      if !@order_shipment.save
        raise "Error saving shipment; errors: " << @order_shipment.errors.inspect
      end    

      if !@order_shipment.generate_fedex_label
        raise "Error generating shipment and saving; errors: " << @order_shipment.errors.inspect
      end
    
      UserMailer.shipping_materials_sent(@order.user, @order_shipment, @order_lines).deliver
      
      return [@order_lines, @order_shipment]
    end # end transaction
  end

  def total_in_cents
    the_total = 0.0
    
    order_lines.each do |order_line|
      the_total += order_line.discount.due_at_signup
    end
    
    the_total
  end
  
  def amount_paid
    the_amount = 0.0
    
    payment_transactions.each do |transaction|
      the_amount += transaction.amount
    end
    
    return the_amount
  end
  
  def amount_charged
    the_amount = 0.0
    
    charges.each do |charge|
      the_amount += charge.total_in_cents
    end
    
    return the_amount/100
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
      charges << Charge.create!(:user_id => user_id, :total_in_cents => (order_line.discount.due_at_signup*100).ceil, :product_id => order_line.product_id, :order_id => self.id)
    end
    
    charges
  end
  
  def vc_box_count
    count_lines(Rails.application.config.our_box_product_id)
  end
  
  def cust_box_count
    count_lines(Rails.application.config.your_box_product_id)
  end
  
  def inv_box_count
    count_lines(Rails.application.config.our_box_inventorying_product_id) + count_lines(Rails.application.config.your_box_inventorying_product_id)
  end
  
  def count_lines(product_id)
    total = 0
    
    order_lines.each do |order_line|
      total += order_line.quantity if order_line.product_id == product_id
    end
    
    total
  end
    
  # Typically, we would just do a before_destroy, or destroy the cart first. Two problems: (1) the order is usually the starting point for administration,
  # so it doesn't make sense to destroy the cart first; and (2) Webrick dies when I call order.destroy directly for who knows what reason. Same thing if I 
  # call self.destroy as the first call in my method. I have to do the cart stuff first. Bizarre.
  def destroy_test_order! 
    cart = self.cart
    # inventory orders don't have a cart
    if cart
      cart.cart_items.each do |cart_item|
        cart_item.destroy
      end
      cart.destroy
    end
    
    self.destroy
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

      if order_line.committed_months.nil? || order_line.committed_months == 0
        subscription = nil
      else
        subscription = Subscription.create!(:duration_in_months => order_line.committed_months, :user_id => self.user_id)
      end
      
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
        if !Box.create!(:assigned_to_user_id => user.id, :ordering_order_line_id => order_line.id, :status => status, :box_type => type, \
          :indexing_status => Box::NO_INDEXING_REQUESTED, :subscription_id => (subscription.nil? ? nil : subscription.id))
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
