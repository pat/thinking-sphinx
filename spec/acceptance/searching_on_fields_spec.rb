require 'acceptance/spec_helper'

describe 'Searching on fields', :live => true do
  it "limits results by field" do
    pancakes = Article.create! :title => 'Pancakes'
    waffles  = Article.create! :title => 'Waffles',
      :content => 'Different to pancakes - and not quite as tasty.'
    index

    articles = Article.search :conditions => {:title => 'pancakes'}
    articles.should include(pancakes)
    articles.should_not include(waffles)
  end

  it "limits results for a field from an association" do
    user     = User.create! :name => 'Pat'
    pancakes = Article.create! :title => 'Pancakes', :user => user
    index

    Article.search(:conditions => {:user => 'pat'}).first.should == pancakes
  end

  it "returns results with matches from grouped fields" do
    user     = User.create! :name => 'Pat'
    pancakes = Article.create! :title => 'Pancakes', :user => user
    waffles  = Article.create! :title => 'Waffles',  :user => user
    index

    Article.search('waffles', :conditions => {:title => 'pancakes'}).to_a.
      should == [pancakes]
  end

  it "returns results with matches from concatenated columns in a field" do
    book = Book.create! :title => 'Night Watch', :author => 'Terry Pratchett'
    index

    Book.search(:conditions => {:info => 'Night Pratchett'}).to_a.
      should == [book]
  end

  it "handles NULLs in concatenated fields" do
    book = Book.create! :title => 'Night Watch'
    index

    Book.search(:conditions => {:info => 'Night Watch'}).to_a.should == [book]
  end

  it "returns results with matches from file fields" do
    file_path = Rails.root.join('tmp', 'caption.txt')
    File.open(file_path, 'w') { |file| file.print 'Cyberpunk at its best' }

    book = Book.create! :title => 'Accelerando', :blurb_file => file_path.to_s

    Book.search('cyberpunk').to_a.should == [book]
  end
end
