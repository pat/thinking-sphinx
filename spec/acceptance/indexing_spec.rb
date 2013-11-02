require 'acceptance/spec_helper'

describe 'Indexing', :live => true do
  it "does not index files where the temp file exists" do
    path = Rails.root.join('db/sphinx/test/ts-article_core.tmp')
    FileUtils.mkdir_p Rails.root.join('db/sphinx/test')
    FileUtils.touch path

    article = Article.create! :title => 'Pancakes'
    index 'article_core'
    Article.search.should be_empty

    FileUtils.rm path
  end

  it "indexes files when other indices are already being processed" do
    path = Rails.root.join('db/sphinx/test/ts-book_core.tmp')
    FileUtils.mkdir_p Rails.root.join('db/sphinx/test')
    FileUtils.touch path

    article = Article.create! :title => 'Pancakes'
    index 'article_core'
    Article.search.should_not be_empty

    FileUtils.rm path
  end
end
