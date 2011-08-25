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
    belongs_to :billing_address, :class_name => 'Address', :dependent => :destroy, :autosave => true
    accepts_nested_attributes_for :billing_address, :allow_destroy => true
    
    attr_accessor :number, :verification_value
        
    # Really we should be validating billing address, but then rails won't let us automatically set a billing address, so we can't create the payment profile
    # using Devise. The right solution to this is to have Devise allow for customization of create, but that isn't possible. Arg!
    validates_presence_of :last_four_digits, :year, :first_name, :last_name, :month
    validates_presence_of :billing_address, :message => "Billing address must be selected."
    validate :validate_card, :on => :create

    def PaymentProfile.new(attributes=nil)
      profile = super(attributes)
      profile.active = true
      profile.billing_address = Address.new
      
      profile
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
    
    def billing_address_id=(value)
      # a bit of a hack, gets around rails auto-setting fields when that would be inappropriate in some cases
      if value.to_f == 0.0
        write_attribute(:billing_address_id, nil)
        self.billing_address_without_extension = nil
      else
        self.billing_address = Address.find(value)
      end
    end
    
    def billing_address_with_extension=(value)
      target_attributes = value.attributes

      target_attributes["user_id"] = nil
      target_attributes.delete("created_at")
      target_attributes.delete("updated_at")

      # The convoluted check on address should never be needed, but is included just in case there's a data problem so we can never overwrite a customer's address info.
      if billing_address.nil? || (!billing_address.user.nil? || billing_address_id == Rails.application.config.fedex_vc_address_id)
        self.billing_address_without_extension = Address.new(target_attributes)
      else
        self.billing_address.attributes = target_attributes
      end
    end
    
    alias_method_chain :billing_address=, :extension

    def number=(value)
      if value.nil?
        self.last_four_digits = nil
      else
        self.last_four_digits = value[-4,4]
        self.cc_type = calculate_cc_type(value)
      end
      @number = value
    end

    def credit_card
      ActiveMerchant::Billing::CreditCard.new(:number => self.number, :month => self.month, :year => self.year, \
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
                      :address2 => nil, #address.address_line_2,
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
    
    def calculate_cc_type(number)
      length = number.size
      
      if length == 15 && number =~ /^(34|37)/
        "amex"
      elsif length == 16 && number =~ /^6011/
        "discover"
      elsif length == 16 && number =~ /^5[1-5]/
        "mastercard"
      elsif (length == 13 || length == 16) && number =~ /^4/
        "visa"
      elsif length == 14 && number =~ /^(300|301|302|303|304|305)/
        "diners club carte blanche"
      elsif length == 14 && number =~ /^(30|36|38|39)/
        "diners club international"
      elsif length == 16 && number =~ /^(54|55)/
        "diners club US & Canada"
      else
        nil
      end
    end
end
