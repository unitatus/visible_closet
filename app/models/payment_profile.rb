# == Schema Information
# Schema version: 20110804223752
#
# Table name: payment_profiles
#
#  id                 :integer         not null, primary key
#  identifier         :string(255)
#  last_four_digits   :string(255)
#  user_id            :integer
#  created_at         :datetime
#  updated_at         :datetime
#  year               :integer
#  first_name         :string(255)
#  last_name          :string(255)
#  billing_address_id :integer
#  cc_type            :string(255)
#  month              :string(255)
#  active             :boolean
#

class PaymentProfile < ActiveRecord::Base
    belongs_to :user
    belongs_to :billing_address, :class_name => 'Address'
    
    attr_accessor :number, :verification_value
    
    # Really we should be validating billing address, but then rails won't let us automatically set a billing address, so we can't create the payment profile
    # using Devise. The right solution to this is to have Devise allow for customization of create, but that isn't possible. Arg!
    validates_presence_of :last_four_digits, :year, :first_name, :last_name, :cc_type, :month
    validate :validate_card, :on => :create

    def PaymentProfile.new(params=nil)
      payment = super(params)
      payment.active ||= true

      payment
    end

    def PaymentProfile.new_from(profile)
      new_profile = PaymentProfile.new
      new_profile.billing_address_id = profile.billing_address_id
      new_profile.user_id = profile.user_id
      new_profile.year = profile.year
      new_profile.first_name = profile.first_name
      new_profile.last_name = profile.last_name
      new_profile.billing_address_id = profile.billing_address_id
      new_profile.cc_type = profile.cc_type
      new_profile.month = profile.month
      new_profile.verification_value = profile.verification_value
      new_profile.number = profile.number
      
      profile.errors.each do |attr, msg|
        new_profile.errors.add(attr, msg)
      end
      
      new_profile      
    end

    def number=(value)
      if value.nil?
        self.last_four_digits = nil
      else
        self.last_four_digits = value[-4,4]
      end
      @number = value
    end

    def credit_card
      ActiveMerchant::Billing::CreditCard.new(:number => self.number, :type => self.cc_type, :month => self.month, :year => self.year, \
      :first_name => self.first_name, :last_name => self.last_name, :verification_value => self.verification_value)
    end
      
    def active=(value)
      if active.nil?
        write_attribute(:active, value)
      elsif (!active? && value == true)
        raise "Cannot move from inactive to active by setting active indicator"
      else 
        write_attribute(:active, value)
        if value == false
          inactivate
        end
      end
    end
    
    def inactivate
      write_attribute(:active, false)
      if delete_payment_profile
        identifier = nil
        return true
      else
        return false
      end
    end
    
    # Assumes a Visible Closet address object; need to map it to an ActiveMerchant address hash
    def address_hash
      if self.billing_address_id.nil?
        nil
      else
        address = Address.find(self.billing_address_id)
        return { :name => address.first_name + " " + address.last_name,
                      :address1 => address.address_line_1,
                      :address2 => address.address_line_2,
                      :company => nil, # not supported at this time
                      :city => address.city,
                      :state => address.state,
                      :zip => address.zip,
                      :country => address.country,
                      :phone => address.day_phone }
      end
    end
    
    def create
      if super and (self.user_id.nil? || create_payment_profile)
        return true
      else
        if self.id
          #destroy the instance if it was created
          self.destroy
        end
        return false
      end
    end

    def destroy
      if !user.nil? && user.default_payment_profile == self
        user.update_attribute(:default_payment_profile_id, nil)
      end
      
      if delete_payment_profile and super
        return true
      end
      return false
    end

    def create_payment_profile
      if not self.id
        return false
      end

      profile = {:customer_profile_id => user.cim_id,
                  :payment_profile => {:bill_to => self.address_hash,
                                       :payment => {:credit_card => self.credit_card}
                                       }
                  }

      response = CIM_GATEWAY.create_customer_payment_profile(profile)
      if response.success? and response.params['customer_payment_profile_id']
        if update_attribute(:identifier, response.params['customer_payment_profile_id'])
          @credit_card = nil
          return true
        else
          puts("Unable to save identifier attribute on new payment profile; errors: " << errors.inspect)
          return false
        end
      else
        errors.add("cc_response", response.message)
        return false
      end
    end

    private
    
    def validate_card
      cc = credit_card
      unless cc.valid?
        cc.errors.each do |attr, messages|
          messages.each do | message |
            if attr == "type"
              attr = "cc_type"
            end
            errors.add(attr, message)
          end
        end
      end
    end
    
    # def validate_save_billing_address_id
    #   if billing_address.nil?
    #     if user.nil? || user.default_shipping_address.nil?
    #       errors.add(:billing_address_id, "Billing address id must be set or user with default shipping address must be associated.")
    #     else
    #       billing_address = user.default_shipping_address
    #     end
    #   end
    # end

    # Updates are not allowed, but this method is kept around just in case, since it may prove useful.
    # def update_payment_profile
    #   profile = {:customer_profile_id => user.cim_id,
    #               :payment_profile => {:customer_payment_profile_id => self.identifier,
    #                                    :bill_to => self.address_hash,
    #                                    :payment => {:credit_card => self.credit_card}
    #                                    }
    #               }
    #   response = CIM_GATEWAY.update_customer_payment_profile(profile)
    #   if response.success?
    #     self.credit_card = nil
    #     return true
    #   else
    #     errors.add("cc_response", response.message)
    #     return false
    #   end
    # end

    def delete_payment_profile
      if self.identifier
        response = CIM_GATEWAY.delete_customer_payment_profile(:customer_profile_id => self.user.cim_id,
                                                            :customer_payment_profile_id => self.identifier)
        if response.success?
          return true
        else
          errors.add("cc_response", response.message)
          return false
        end
      end
      
      return true
    end
end
