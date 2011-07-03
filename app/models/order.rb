# == Schema Information
# Schema version: 20110701051132
#
# Table name: orders
#
#  id                  :integer         not null, primary key
#  cart_id             :integer
#  ip_address          :string(255)
#  user_id             :integer
#  created_at          :datetime
#  updated_at          :datetime
#  billing_address_id  :integer
#  shipping_address_id :integer
#

class Order < ActiveRecord::Base
  belongs_to :cart
  has_many :payment_transactions

  attr_accessor :card_number, :card_verification_value, :card_first_name, :card_last_name, :card_type, :card_month, :card_year

  validate :validate_card, :on => :create

  def purchase
    response = PURCHASE_GATEWAY.purchase(total_in_cents, credit_card, purchase_options)
    payment_transactions.create!(:action => "purchase", :amount => total_in_cents, :response => response)
    cart.mark_ordered if response.success?

    errors.add("cc_response", response.message) unless response.success?
    response.success?
  end

  def total_in_cents
    (cart.estimated_total*100).round
  end

  private

  def purchase_options
    billing_address = Address.find(billing_address_id)
    {
      :ip => ip_address,
      :billing_address => {
        :name => billing_address.first_name + " " + billing_address.last_name,
        :address1 => billing_address.address_line_1,
        :address2 => billing_address.address_line_2,
        :city => billing_address.city,
        :state => billing_address.state,
        :country => billing_address.country,
        :zip => billing_address.zip
      }
    }
  end

  def validate_card
    unless credit_card.valid?
      credit_card.errors.each do |attr, messages|
        messages.each do | message |
          errors.add("card_" + attr, message)
        end
      end
    end
  end

  def credit_card
    @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
      :type => card_type,
      :number => card_number,
      :verification_value => card_verification_value,
      :month => card_month,
      :year => card_year,
      :first_name => card_first_name,
      :last_name => card_last_name
    )
  end

end
