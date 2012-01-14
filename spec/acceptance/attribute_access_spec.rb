require 'acceptance/spec_helper'

describe 'Accessing attributes directly via search results', :live => true do
  it "allows access to attribute values" do
    Book.create! :title => 'American Gods', :year => 2001
    index

    Book.search('gods').first.sphinx_attributes[:year].should == 2001
  end
end
