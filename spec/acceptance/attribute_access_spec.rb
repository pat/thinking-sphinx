# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Accessing attributes directly via search results', :live => true do
  it "allows access to attribute values" do
    Book.create! :title => 'American Gods', :year => 2001
    index

    search = Book.search('gods')
    search.context[:panes] << ThinkingSphinx::Panes::AttributesPane

    expect(search.first.sphinx_attributes['year']).to eq(2001)
  end

  it "provides direct access to the search weight/relevance scores" do
    Book.create! :title => 'American Gods', :year => 2001
    index

    search = Book.search 'gods',
      :select => "*, #{ThinkingSphinx::SphinxQL.weight[:select]}"
    search.context[:panes] << ThinkingSphinx::Panes::WeightPane

    expect(search.first.weight).to eq(2500)
  end

  it "can enumerate with the weight" do
    gods = Book.create! :title => 'American Gods', :year => 2001
    index

    search = Book.search 'gods',
      :select => "*, #{ThinkingSphinx::SphinxQL.weight[:select]}"
    search.masks << ThinkingSphinx::Masks::WeightEnumeratorMask

    expectations = [[gods, 2500]]
    search.each_with_weight do |result, weight|
      expectation = expectations.shift

      expect(result).to eq(expectation.first)
      expect(weight).to eq(expectation.last)
    end
  end
end
