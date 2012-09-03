require 'acceptance/spec_helper'

describe 'Faceted searching', :live => true do
  it "provides facet breakdowns across marked attributes" do
    blue  = Colour.create! :name => 'blue'
    red   = Colour.create! :name => 'red'
    green = Colour.create! :name => 'green'

    Tee.create! :colour => blue
    Tee.create! :colour => blue
    Tee.create! :colour => red
    Tee.create! :colour => green
    Tee.create! :colour => green
    Tee.create! :colour => green
    index

    Tee.facets.to_hash.should == {
      :colour_id => {blue.id => 2, red.id => 1, green.id => 3}
    }
  end
end
