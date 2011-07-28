require File.dirname(__FILE__) + '/../spec_helper'

describe PaymentProfile do
  before(:each) do
     @user = User.new(:first_name => 'Joe', :last_name => 'Test', :password => 'asdffdas', :email => 'test@thevisiblecloset.com')

     @user.should be_valid

     @user.save
     @user.cim_id = '20082887'
     @user.save

     @address = Address.new(:first_name => @user.first_name, :last_name => @user.last_name, :day_phone => '1231231232', :address_line_1 => '123 Sesame', :city => 'Evanston', :state => 'IL', :zip => '60202', :user_id => @user.id)

     @address.save

     @address.should be_valid

     @cc = ActiveMerchant::Billing::CreditCard.new(:type => 'Visa', :number => '4111111111111111', :verification_value =>  '123', :month => '12', :year => '2012', :first_name => @user.first_name, :last_name => @user.last_name)
  end

  it "should create a new instance given valid attributes" do
    profile = PaymentProfile.new()
    profile.user_id = @user.id
    profile.address = @address
    profile.credit_card = @cc

    profile.save
    assert_equal(0, profile.errors.size, "Got errors: " << profile.errors.inspect)

    profile.identifier.should_not be_nil
    profile.address.should be_nil
    profile.credit_card.should be_nil

    profile = PaymentProfile.find(profile.id)
    profile.identifier.should_not be_nil

    @address.address_line_1 = @address.address_line_1 + " 2"

    profile.address = @address
    profile.credit_card = @cc

    profile.save

    assert_equal(0, profile.errors.size, "Got errors: " << profile.errors.inspect)
    profile.address.should be_nil
    profile.credit_card.should be_nil

    profile.destroy.should be_true
  end
end
