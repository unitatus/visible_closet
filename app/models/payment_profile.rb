# == Schema Information
# Schema version: 20110729015304
#
# Table name: payment_profiles
#
#  id                 :integer         not null, primary key
#  identifier         :string(255)
#  last_four_digits   :string(255)
#  user_id            :integer
#  created_at         :datetime
#  updated_at         :datetime
#  exp_year           :integer
#  first_name         :string(255)
#  last_name          :string(255)
#  billing_address_id :integer
#  cc_type            :string(255)
#  exp_month          :string(255)
#

class PaymentProfile < ActiveRecord::Base
    belongs_to :user

    attr_accessor :credit_card
    
    validates_presence_of :user_id, :credit_card, :billing_address_id
    
    validate :validate_card, :on => :create

    def credit_card=(cc)
      if not cc.nil?
        self.last_four_digits = cc.number[-4,4]
        self.cc_type = cc.type
        self.exp_month = cc.month
        self.exp_year = cc.year
        self.first_name = cc.first_name
        self.last_name = cc.last_name
      end
      
      @credit_card = cc
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
      if super and create_payment_profile
        return true
      else
        if self.id
          #destroy the instance if it was created
          self.destroy
        end
        return false
      end
    end

    def update
      if super and update_payment_profile
        return true
      end
      return false
    end

    def destroy
      if delete_payment_profile and super
        return true
      end
      return false
    end

    private
    
    def validate_card
      unless @credit_card.valid?
        @credit_card.errors.each do |attr, messages|
          messages.each do | message |
            errors.add("card_" + attr, message)
          end
        end
      end
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
        update_attribute(:identifier, response.params['customer_payment_profile_id'])
        self.credit_card = nil
        return true
      else
        errors.add("cc_response", response.message)
        return false
      end
    end

    def update_payment_profile
      profile = {:customer_profile_id => user.cim_id,
                  :payment_profile => {:customer_payment_profile_id => self.identifier,
                                       :bill_to => self.address_hash,
                                       :payment => {:credit_card => self.credit_card}
                                       }
                  }
      response = CIM_GATEWAY.update_customer_payment_profile(profile)
      if response.success?
        self.credit_card = nil
        return true
      else
        errors.add("cc_response", response.message)
        return false
      end
    end

    def delete_payment_profile
      response = CIM_GATEWAY.delete_customer_payment_profile(:customer_profile_id => self.user.cim_id,
                                                          :customer_payment_profile_id => self.identifier)
      if response.success?
        return true
      else
        errors.add("cc_response", response.message)
        return false
      end
    end
end
