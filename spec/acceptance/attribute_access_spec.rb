# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Accessing attributes directly via search results', :live => true do
  it "allows access to attribute values" do
    Book.create! :title => 'American Gods', :publishing_year => 2001
    index

    search = Book.search('gods')
    search.context[:panes] << ThinkingSphinx::Panes::AttributesPane

    expect(search.first.sphinx_attributes['publishing_year']).to eq(2001)
  end

  it "provides direct access to the search weight/relevance scores" do
    Book.create! :title => 'American Gods', :publishing_year => 2001
    index

    search = Book.search 'gods', :select => "*, weight()"
    search.context[:panes] << ThinkingSphinx::Panes::WeightPane

    if ENV["SPHINX_ENGINE"] == "sphinx" && ENV["SPHINX_VERSION"].to_f > 3.3
      expect(search.first.weight).to eq(20_000.0)
    else
      expect(search.first.weight).to eq(2500)
    end
  end

  it "provides direct access to the weight with alternative primary keys" do
    album = Album.create! :name => 'Sing to the Moon', :artist => 'Laura Mvula'

    search = Album.search 'sing', :select => "*, weight()"
    search.context[:panes] << ThinkingSphinx::Panes::WeightPane

    expect(search.first.weight).to be >= 1000
  end

  it "can enumerate with the weight" do
    gods = Book.create! :title => 'American Gods', :publishing_year => 2001
    index

    search = Book.search 'gods', :select => "*, weight()"
    search.masks << ThinkingSphinx::Masks::WeightEnumeratorMask

    if ENV["SPHINX_ENGINE"] == "sphinx" && ENV["SPHINX_VERSION"].to_f > 3.3
      expectations = [[gods, 20_000.0]]
    else
      expectations = [[gods, 2500]]
    end
    search.each_with_weight do |result, weight|
      expectation = expectations.shift

      expect(result).to eq(expectation.first)
      expect(weight).to eq(expectation.last)
    end
  end
end
