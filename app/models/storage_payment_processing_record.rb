# == Schema Information
# Schema version: 20110930213450
#
# Table name: storage_payment_processing_records
#
#  id                   :integer         not null, primary key
#  generated_by_user_id :integer
#  as_of_date           :datetime
#  created_at           :datetime
#  updated_at           :datetime
#

class StoragePaymentProcessingRecord < ActiveRecord::Base
  belongs_to :generated_by, :class_name => "User", :foreign_key => :generated_by_user_id
  has_many :payment_transactions, :dependent => :destroy
  
  def add_payment_transactions(payment)
    if payment.status == PaymentTransaction::RECTIY_STATUS
      @contains_rectify_payments = true
    else
      @contains_rectify_payments ||= false
    end
    
    payment_transactions << payment
  end
  
  def contains_rectify_payments?
    if @contains_rectify_payments.nil?
      payment_transactions.each do |payment|
        if payment.rectify?
          @contains_rectify_payments = true
        end
      end
    end
    
    @contains_rectify_payments
  end
  
  def rectify_payments
    payment_transactions.select {|payment| payment.rectify? }
  end
  
  def non_rectify_payments
    payment_transactions.select {|payment| !payment.rectify? }
  end
end
