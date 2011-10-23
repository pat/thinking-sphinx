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

  it "automatically indexes updated records" do
    book = Book.create :title => 'Night Watch', :author => 'Harry Pritchett'
    index

    Book.search('Harry').to_a.should == [book]

    book.reload.update_attributes(:author => 'Terry Pratchett')
    sleep 0.25

    Book.search('Terry').to_a.should == [book]
  end

  it "does not match on old values" do
    book = Book.create :title => 'Night Watch', :author => 'Harry Pritchett'
    index

    Book.search('Harry').to_a.should == [book]

    book.reload.update_attributes(:author => 'Terry Pratchett')
    sleep 0.25

    Book.search('Harry').should be_empty
  end
end
