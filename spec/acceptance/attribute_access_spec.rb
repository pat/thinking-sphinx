require 'acceptance/spec_helper'

describe 'Accessing attributes directly via search results', :live => true do
  it "allows access to attribute values" do
    Book.create! :title => 'American Gods', :year => 2001
    index

    Book.search('gods').first.sphinx_attributes[:year].should == 2001
  end

  it "provides direct access to the search weight/relevance scores" do
    Book.create! :title => 'American Gods', :year => 2001
    index

    Book.search('gods').first.weight.should == 3500
  end
end
