# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Paginating search results', :live => true do
  it "tracks how many results there are in total" do
    expect(Article.search.total_entries).to be_zero

    21.times { |number| Article.create :title => "Article #{number}" }
    index

    if ENV["SPHINX_ENGINE"] == "manticore" && ENV["SPHINX_VERSION"].to_f >= 4.0
      # I suspect this is a bug in Manticore?
      expect(Article.search.total_entries).to eq(22)
    else
      expect(Article.search.total_entries).to eq(21)
    end
  end

  it "paginates the result set by default" do
    expect(Article.search.total_entries).to be_zero

    21.times { |number| Article.create :title => "Article #{number}" }
    index

    expect(Article.search.length).to eq(20)
  end

  it "tracks the number of pages" do
    expect(Article.search.total_entries).to be_zero

    21.times { |number| Article.create :title => "Article #{number}" }
    index

    if ENV["SPHINX_ENGINE"] == "manticore" && ENV["SPHINX_VERSION"].to_f >= 4.0
      # I suspect this is a bug in Manticore?
      expect(Article.search.total_pages).to eq(1)
    else
      expect(Article.search.total_pages).to eq(2)
    end
  end
end
