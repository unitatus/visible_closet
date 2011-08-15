require File.dirname(__FILE__) + '/../spec_helper'

describe Discount do
  before(:each) do
  end

  it "should return correct discounts" do
    discount = Discount.new(Product.find(Rails.application.config.our_box_product_id), 1, 1)
  end
end
