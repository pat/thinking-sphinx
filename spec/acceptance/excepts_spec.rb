require 'acceptance/spec_helper'

describe 'Accessing excerpts for methods on a search result', :live => true do
  it "returns excerpts for a given method" do
    Book.create! :title => 'American Gods', :year => 2001
    index

    Book.search('gods').first.excerpts.title.
      should == 'American <span class="match">Gods</span>'
  end
end
