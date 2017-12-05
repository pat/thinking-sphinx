# frozen_string_literal: true

require 'acceptance/spec_helper'

describe 'Paginating search results', :live => true do
  it "tracks how many results there are in total" do
    21.times { |number| Article.create :title => "Article #{number}" }
    index

    expect(Article.search.total_entries).to eq(21)
  end

  it "paginates the result set by default" do
    21.times { |number| Article.create :title => "Article #{number}" }
    index

    expect(Article.search.length).to eq(20)
  end

  it "tracks the number of pages" do
    21.times { |number| Article.create :title => "Article #{number}" }
    index

    expect(Article.search.total_pages).to eq(2)
  end
end
