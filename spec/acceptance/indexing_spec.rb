require 'acceptance/spec_helper'

describe 'Indexing', :live => true do
  it "does not index files where the temp file exists" do
    path = Rails.root.join('db/sphinx/test/ts-article_core.tmp')
    FileUtils.mkdir_p Rails.root.join('db/sphinx/test')
    FileUtils.touch path

    article = Article.create! :title => 'Pancakes'
    index 'article_core'
    expect(Article.search).to be_empty

    FileUtils.rm path
  end

  it "indexes files when other indices are already being processed" do
    path = Rails.root.join('db/sphinx/test/ts-book_core.tmp')
    FileUtils.mkdir_p Rails.root.join('db/sphinx/test')
    FileUtils.touch path

    article = Article.create! :title => 'Pancakes'
    index 'article_core'
    expect(Article.search).not_to be_empty

    FileUtils.rm path
  end

  it "cleans up temp files even when an exception is raised" do
    FileUtils.mkdir_p Rails.root.join('db/sphinx/test')

    index 'article_core'

    file = Rails.root.join('db/sphinx/test/ts-article_core.tmp')
    expect(File.exist?(file)).to be_falsey
  end
end
