# == Schema Information
# Schema version: 20110701051132
#
# Table name: payment_profiles
#
#  id               :integer         not null, primary key
#  identifier       :string(255)
#  last_four_digits :string(255)
#  user_id          :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class PaymentProfile < ActiveRecord::Base
    belongs_to :user

    attr_accessor :address
    attr_accessor :credit_card

    validates_presence_of :user_id, :credit_card, :address

    def credit_card=(cc)
      if not cc.nil?
        self.last_four_digits = cc.number[-4,4]
      end
      
      @credit_card = cc
    end
    
    # Assumes a Visible Closet address object; need to map it to an ActiveMerchant address hash
    def address=(new_address)
      if new_address.nil?
        @address = nil
      else
        @address = { :name => new_address.first_name + " " + new_address.last_name,
                      :address1 => new_address.address_line_1,
                      :address2 => new_address.address_line_2,
                      :company => nil, # not supported at this time
                      :city => new_address.city,
                      :state => new_address.state,
                      :zip => new_address.zip,
                      :country => new_address.country,
                      :phone => new_address.day_phone }
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
    def create_payment_profile
      if not self.id
        return false
      end

      profile = {:customer_profile_id => user.cim_id,
                  :payment_profile => {:bill_to => self.address,
                                       :payment => {:credit_card => self.credit_card}
                                       }
                  }

      response = CIM_GATEWAY.create_customer_payment_profile(profile)
      if response.success? and response.params['customer_payment_profile_id']
        update_attribute(:identifier, response.params['customer_payment_profile_id'])
        self.address = nil
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
                                       :bill_to => self.address,
                                       :payment => {:credit_card => self.credit_card}
                                       }
                  }
      response = CIM_GATEWAY.update_customer_payment_profile(profile)
      if response.success?
        self.address = nil
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
