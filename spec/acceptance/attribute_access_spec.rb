require 'acceptance/spec_helper'

describe 'Accessing attributes directly via search results', :live => true do
  it "allows access to attribute values" do
    Book.create! :title => 'American Gods', :year => 2001
    index

    search = Book.search('gods')
    search.context[:panes] << ThinkingSphinx::Panes::AttributesPane

    search.first.sphinx_attributes['year'].should == 2001
  end

  it "provides direct access to the search weight/relevance scores" do
    Book.create! :title => 'American Gods', :year => 2001
    index

    search = Book.search('gods', :select => '*, @weight')
    search.context[:panes] << ThinkingSphinx::Panes::WeightPane

    search.first.weight.should == 3500
  end

  it "can enumerate with the weight" do
    gods = Book.create! :title => 'American Gods', :year => 2001
    index

    search = Book.search('gods', :select => '*, @weight')
    search.masks << ThinkingSphinx::Masks::WeightEnumeratorMask

    expectations = [[gods, 3500]]
    search.each_with_weight do |result, weight|
      expectation = expectations.shift

      result.should == expectation.first
      weight.should == expectation.last
    end
  end
end
