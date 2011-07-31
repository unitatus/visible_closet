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
  # TODO: Implement charges relationship, and give a charge a quantity and an invoice id
  # has_many :charges
  
  class InvoiceLine
    attr_accessor :product, :quantity
    
    def total_in_cents
      return @product.price * @quantity * 100
    end
  end
  
  def invoice_lines(refresh = false)
    if refresh || @invoice_lines.nil?
      # if this is an order, return order lines; if for charges, return charges
      @invoice_lines = Array.new
    
      order.order_lines.each do |line|
        new_invoice_line = InvoiceLine.new()
        new_invoice_line.product = line.product
        new_invoice_line.quantity = line.quantity
        
        @invoice_lines << new_invoice_line
      end
    end
    
    @invoice_lines
  end
  
  def total_in_cents
    the_total = 0.0
    
    self.invoice_lines.each do |line|
      the_total += line.total_in_cents
    end
    
    return the_total
  end
end
