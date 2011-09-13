# == Schema Information
# Schema version: 20110731151623
#
# Table name: invoices
#
#  id                     :integer         not null, primary key
#  user_id                :integer
#  payment_transaction_id :integer
#  order_id               :integer
#  created_at             :datetime
#  updated_at             :datetime
#

class Invoice < ActiveRecord::Base
  belongs_to :user
  belongs_to :order
  belongs_to :payment_transaction
  
  class InvoiceLine
    attr_accessor :product, :quantity, :unit_price, :months_paid, :discount, :shipping_address
  end
  
  def invoice_lines(refresh = false)
    if refresh || @invoice_lines.nil?
      # if this is an order, return order lines; if for charges, return charges
      @invoice_lines = Array.new
    
      order.order_lines.each do |line|
        new_invoice_line = InvoiceLine.new()
        new_invoice_line.product = line.product
        new_invoice_line.quantity = line.quantity
        new_invoice_line.unit_price = line.unit_price_after_discount
        new_invoice_line.months_paid = line.discount.months_due_at_signup
        new_invoice_line.discount = line.discount
        new_invoice_line.shipping_address = line.shipping_address
        
        @invoice_lines << new_invoice_line
      end
    end
    
    @invoice_lines
  end
  
  def subtotal_in_cents
    the_total = 0.0
    
    self.invoice_lines.each do |line|
      the_total += line.discount.due_at_signup
    end
    
    return the_total*100
  end
  
  def total_in_cents
    return subtotal_in_cents + shipping_cost*100
  end
  
  def free_shipping?
    self.invoice_lines.each do |line|
      if !line.discount.free_shipping?
        return false
      end
    end
    
    return true
  end
  
  def contains_only_ordered_boxes
    the_ordered_box_lines = self.ordered_box_lines
    
    return the_ordered_box_lines.size > 0 && the_ordered_box_lines.size == self.invoice_lines.size
  end
  
  def contains_ordered_boxes
    ordered_box_lines.size > 0 
  end
  
  def ordered_box_lines
    self.invoice_lines.select { |invoice_line| invoice_line.product.id == Rails.application.config.your_box_product_id \
      || invoice_line.product.id == Rails.application.config.our_box_product_id }
  end
  
  def shipping_cost
    self.order.initial_charged_shipping_cost
  end
end
