require 'acceptance/spec_helper'

describe 'Suspend deltas for a given action', :live => true do
  it "does not update the delta indices until after the block is finished" do
    book = Book.create :title => 'Night Watch', :author => 'Harry Pritchett'
    index

    Book.search('Harry').to_a.should == [book]

    ThinkingSphinx::Deltas.suspend :book do
      book.reload.update_attributes(:author => 'Terry Pratchett')
      sleep 0.25

      Book.search('Terry').to_a.should == []
    end

    sleep 0.25
    Book.search('Terry').to_a.should == [book]
  end
end
