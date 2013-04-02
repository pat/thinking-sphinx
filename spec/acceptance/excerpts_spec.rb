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
  end
end
