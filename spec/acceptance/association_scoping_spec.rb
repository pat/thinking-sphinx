require 'acceptance/spec_helper'

describe 'Scoping association search calls by foreign keys', :live => true do
  it "limits results to those matching the foreign key" do
    pat       = User.create :name => 'Pat'
    melbourne = Article.create :title => 'Guide to Melbourne', :user => pat
    paul      = User.create :name => 'Paul'
    dublin    = Article.create :title => 'Guide to Dublin',    :user => paul
    index

    pat.articles.search('Guide').to_a.should == [melbourne]
  end

  it "limits id-only results to those matching the foreign key" do
    pat       = User.create :name => 'Pat'
    melbourne = Article.create :title => 'Guide to Melbourne', :user => pat
    paul      = User.create :name => 'Paul'
    dublin    = Article.create :title => 'Guide to Dublin',    :user => paul
    index

    pat.articles.search_for_ids('Guide').to_a.should == [melbourne.id]
  end
end
