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

    if ActiveRecord::Base.configurations['test']['adapter'][/postgres/]
      Book.search('gods').first.weight.should == 2500
    else # mysql
      Book.search('gods').first.weight.should == 3500
    end
  end

  it "can enumerate with the weight" do
    gods = Book.create! :title => 'American Gods', :year => 2001
    index

    expectations = [[gods]]
    if ActiveRecord::Base.configurations['test']['adapter'][/postgres/]
      expectations.first << 2500
    else # mysql
      expectations.first << 3500
    end

    search = Book.search('gods')
    search.masks << ThinkingSphinx::Masks::WeightEnumeratorMask

    search.each_with_weight do |result, weight|
      expectation = expectations.shift

      result.should == expectation.first
      weight.should == expectation.last
    end
  end
end
