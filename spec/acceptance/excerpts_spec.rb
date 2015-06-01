# encoding: utf-8

require 'acceptance/spec_helper'

describe 'Accessing excerpts for methods on a search result', :live => true do
  it "returns excerpts for a given method" do
    Book.create! :title => 'American Gods', :year => 2001
    index

    search = Book.search('gods')
    search.context[:panes] << ThinkingSphinx::Panes::ExcerptsPane

    search.first.excerpts.title.
      should == 'American <span class="match">Gods</span>'
  end

  it "handles UTF-8 text for excerpts" do
    Book.create! :title => 'Война и миръ', :year => 1869
    index

    search = Book.search 'миръ'
    search.context[:panes] << ThinkingSphinx::Panes::ExcerptsPane

    search.first.excerpts.title.
      should == 'Война и <span class="match">миръ</span>'
  end if ENV['SPHINX_VERSION'].try :[], /2.2.\d/

  it "does not include class names in excerpts" do
    Book.create! :title => 'The Graveyard Book'
    index

    search = Book.search('graveyard')
    search.context[:panes] << ThinkingSphinx::Panes::ExcerptsPane

    search.first.excerpts.title.
      should == 'The <span class="match">Graveyard</span> Book'
  end

  it "respects the star option with queries" do
    Article.create! :title => 'Something'
    index

    search = Article.search('thin', :star => true)
    search.context[:panes] << ThinkingSphinx::Panes::ExcerptsPane

    search.first.excerpts.title.
      should == '<span class="match">Something</span>'
  end
end
