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
    attr_accessor :product, :quantity, :unit_price, :months_paid, :discount, :shipping_address, :service_box, :box_order_line, :shippable
    
    def description
      if product.id == Rails.application.config.return_box_product_id
        product.name + " for box " + service_box.box_num.to_s
      else
        product.name
      end
    end
    
    def box_order_line?
      self.box_order_line
    end
    
    def shippable?
      self.shippable
    end
  end
  
  def only_non_shippable_lines?
    self.invoice_lines.each do |line|
      if line.shippable?
        return false
      end
    end
    
    return true
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
        new_invoice_line.service_box = line.service_box
        new_invoice_line.box_order_line = line.box_order_line?
        new_invoice_line.shippable = line.shippable?
        
        @invoice_lines << new_invoice_line
      end
    end
    
    @invoice_lines
  end
  
  def subtotal_in_cents
    the_total = 0.0
    
    self.invoice_lines.each do |line|
      the_total += line.discount.charged_at_purchase + line.discount.prepaid_at_purchase
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
    self.order.contains_only_ordered_boxes
  end
  
  def contains_ordered_boxes
    self.order.contains_ordered_boxes
  end
  
  def ordered_box_lines
    self.order.ordered_box_lines
  end
  
  def shipping_cost
    self.order.initial_charged_shipping_cost
  end
  
  def quoted_shipping_cost_success
    self.order.quoted_shipping_cost_success
  end
end
