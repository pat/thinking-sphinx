require 'acceptance/spec_helper'

describe 'Updates to records in real-time indices', :live => true do
  it "handles fields with unicode nulls" do
    product = Product.create! :name => "Widget \u0000"

    expect(Product.search.first).to eq(product)
  end

  it "handles attributes for sortable fields accordingly" do
    product = Product.create! :name => 'Red Fish'
    product.update_attributes :name => 'Blue Fish'

    expect(Product.search('blue fish', :indices => ['product_core']).to_a).
      to eq([product])
  end
end
