require 'acceptance/spec_helper'

describe 'Updates to records in real-time indices', :live => true do
  it "handles fields with unicode nulls" do
    product = Product.create! :name => "Widget \u0000"

    Product.search.first.should == product
  end
end
