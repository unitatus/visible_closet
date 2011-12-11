class OrderLine < ActiveRecord::Base
  NEW_STATUS = "new"
  PROCESSED_STATUS = "processed"
  CANCELLED_STATUS = "cancelled"
  
  belongs_to :order
  belongs_to :product
  belongs_to :shipping_address, :class_name => 'Address'
  belongs_to :service_box, :class_name => 'Box'
  belongs_to :shipment
  belongs_to :service_item, :class_name => 'StoredItem'
  belongs_to :item_mail_shipping_charge, :class_name => 'Charge'
  belongs_to :product_charge, :class_name => 'Charge'
  has_many :ordered_boxes, :class_name => 'Box', :foreign_key => :ordering_order_line_id, :dependent => :destroy
  has_many :inventoried_boxes, :foreign_key => :inventorying_order_line_id, :class_name => "Box"
  
  after_initialize :init_status
  before_destroy :dissociate_inventoried_boxes
  
  def init_status
    if status.blank?
      self.status = NEW_STATUS
    end
  end
  
  def process(charity_name=nil, shipping_charge=nil, shipment=nil)
    self.status = PROCESSED_STATUS
    
    self.transaction do

      # This won't do anything on an order line that doe not include associated boxes
      associated_boxes.each do |box|
        box_shipment = box.ship # the box will check its state and behave accordingly; new boxes will have their shipment back to us generated; returned boxes will have their outgoing shipment created
        
        if box_shipment.nil?
          raise "Unable to ship box; errors " << box.errors.inspect
        elsif self.product_id == Rails.application.config.return_box_product_id
          update_attribute(:shipment_id, box.active_shipment.id)
        end
      end
      
      if ordered_boxes.size > 0 # must generate shipment for shipping materials. This can only happen once per order.
        supplies_shipment = Shipment.new
        
        supplies_shipment.from_address_id = Rails.application.config.fedex_vc_address_id
        supplies_shipment.to_address_id = self.shipping_address_id
        
        if !supplies_shipment.save
          raise "Error saving shipment; errors: " << order_shipment.errors.inspect
        end
        
        update_attribute(:shipment_id, supplies_shipment.id)
              
        if !supplies_shipment.generate_fedex_label
          raise "Error generating shipment and saving; errors: " << order_shipment.errors.inspect
        end
      end
      
      if service_item
        self.item_mail_shipping_charge = shipping_charge
        service_item.finalize_service(product, charity_name, shipment)
        self.shipment = shipment
      end
      
      if (!save)
        raise "Unable to save OrderLine " << self.inspect
      end
    end # end transaction
    
    return true # Only hard errors are thrown in the transaction, so if we made it here we are ok
  end
  
  def shippable?
    self.product.shippable?
  end
  
  def total_in_cents
    self.unit_price_after_discount*self.quantity*100
  end
  
  def discount
    # don't need to worry about the products on this order, because they would never be in storage if we are looking at the discount for the order
    Discount.new(product, quantity, committed_months, self.cust_box? ? order.user.stored_cubic_feet_count : order.user.stored_box_count(Box.get_type(product)))
  end
  
  def cust_box?
    product_id == Rails.application.config.your_box_product_id
  end
  
  def vc_box?
    product_id == Rails.application.config.our_box_product_id
  end
  
  def return_box?
    product_id == Rails.application.config.return_box_product_id
  end
  
  def item_service?
    self.product.item_service?
  end
  
  def item_donation?
    self.product.donation?
  end
  
  def item_mailing?
    self.product.item_mailing?
  end
  
  def new?
    self.status == NEW_STATUS
  end
  
  def unit_price_after_discount
    self.discount.unit_price_after_discount
  end
  
  def cancel
    return_msg = ""
    transaction_successful = false
    
    self.transaction do
      update_attribute(:status, CANCELLED_STATUS)
      
      if cust_box? || vc_box?
        ordered_boxes.each do |box|
          box.destroy
        end
      elsif item_service?
        service_item.update_attribute(:status, StoredItem::IN_STORAGE_STATUS)
      elsif box_return?
        raise "Box return cancellation not yet supported."
      end
      
      if !order.payment_transactions.empty?
        amt_to_refund = amount_paid_at_purchase
        original_transaction = order.payment_transactions.first
        original_pmt_profile = original_transaction.payment_profile
        
        refund_payment, auth_message = PaymentTransaction.refund(amt_to_refund, original_pmt_profile, original_transaction)
        
        if refund_payment.nil? 
          return_msg << " Failed to refund on default payment profile as well, with message \"" + auth_message + "\""
          if auth_message == PaymentTransaction::REQUIRES_SETTLEMENT_MSG
            return_msg << " Usually this means that the original payment transaction must be settled -- i.e., wait 24 hours."
          end
          raise ActiveRecord::Rollback
        end
        
        order.payment_transactions << refund_payment
      end
      
      # refund shipping payments - TBD
      
      transaction_successful = true
    end
    
    UserMailer.deliver_order_line_cancelled(self) if transaction_successful
    
    return transaction_successful, return_msg
  end
  
  def associated_boxes
    all_boxes = Array.new
    # since ruby does pass by reference, we have to be careful about making a separate copy of the array, otherwise adding the return box to the ordered box array will make the return box an ordered box!
    all_boxes = all_boxes | ordered_boxes
    returned_box = service_box
    if returned_box
      all_boxes << returned_box # the bug is here. Rails seems to think that all_boxes is the ordered_boxes array, so adding this to the array makes the returned box an ordered box. WTF. Hello pass by value?
    end
    
    all_boxes
  end
  
  def inventorying_line?
    product_id == Rails.application.config.our_box_inventorying_product_id || product_id == Rails.application.config.your_box_inventorying_product_id
  end
  
  def box_order_line?
    product_id == Rails.application.config.our_box_product_id || product_id == Rails.application.config.your_box_product_id
  end
  
  def return_order_line?
    product_id == Rails.application.config.return_box_product_id
  end
  
  def add_to_amount_paid_at_purchase(amount)
    return nil if amount.nil?
    
    if amount_paid_at_purchase.nil?
      update_attribute(:amount_paid_at_purchase, amount)
    else
      update_attribute(:amount_paid_at_purchase, amount_paid_at_purchase + amount)
    end
  end
  
  def OrderLine.total_quantity(order_lines)
    total_quantity = 0
    
    order_lines.each do |line|
      total_quantity += line.quantity
    end
    
    total_quantity
  end
  
  def associated_boxes
    all_boxes = ordered_boxes | inventoried_boxes
    all_boxes << service_box if service_box
    all_boxes
  end
  
  private
  
  def dissociate_inventoried_boxes
    inventoried_boxes.each do |box|
      box.update_attribute(:inventorying_order_line_id, nil)
    end
  end
end
