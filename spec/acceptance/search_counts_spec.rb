require 'acceptance/spec_helper'

describe 'Get search result counts', :live => true do
  it "returns counts for a single model" do
    4.times { |i| Article.create :title => "Article #{i}" }
    index

    Article.search_count.should == 4
  end

  it "returns counts across all models" do
    3.times { |i| Article.create :title => "Article #{i}" }
    2.times { |i| Book.create :title => "Book #{i}" }
    index

    ThinkingSphinx.count.should == 5
  end
end
