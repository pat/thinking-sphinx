require 'acceptance/spec_helper'

describe 'SQL delta indexing', :live => true do
  it "automatically indexes new records" do
    guards = Book.create(
      :title => 'Guards! Guards!', :author => 'Terry Pratchett'
    )
    index

    Book.search('Terry Pratchett').to_a.should == [guards]

    men = Book.create(
      :title => 'Men At Arms', :author => 'Terry Pratchett'
    )
    sleep 0.25

    Book.search('Terry Pratchett').to_a.should == [guards, men]
  end
end
