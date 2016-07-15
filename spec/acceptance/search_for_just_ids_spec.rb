require 'acceptance/spec_helper'

describe 'Searching for just instance Ids', :live => true do
  it "returns just the instance ids" do
    pancakes = Article.create! :title => 'Pancakes'
    waffles  = Article.create! :title => 'Waffles'
    index

    expect(Article.search_for_ids('pancakes').to_a).to eq([pancakes.id])
  end

  it "works across the global context" do
    article = Article.create! :title => 'Pancakes'
    book    = Book.create! :title => 'American Gods'
    index

    expect(ThinkingSphinx.search_for_ids.to_a).to match_array([article.id, book.id])
  end
end
