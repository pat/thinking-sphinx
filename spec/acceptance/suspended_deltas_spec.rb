require 'acceptance/spec_helper'

describe 'Suspend deltas for a given action', :live => true do
  it "does not update the delta indices until after the block is finished" do
    book = Book.create :title => 'Night Watch', :author => 'Harry Pritchett'
    index

    expect(Book.search('Harry').to_a).to eq([book])

    ThinkingSphinx::Deltas.suspend :book do
      book.reload.update_attributes(:author => 'Terry Pratchett')
      sleep 0.25

      expect(Book.search('Terry').to_a).to eq([])
    end

    sleep 0.25
    expect(Book.search('Terry').to_a).to eq([book])
  end

  it "returns core records even though they are no longer valid" do
    book = Book.create :title => 'Night Watch', :author => 'Harry Pritchett'
    index

    expect(Book.search('Harry').to_a).to eq([book])

    ThinkingSphinx::Deltas.suspend :book do
      book.reload.update_attributes(:author => 'Terry Pratchett')
      sleep 0.25

      expect(Book.search('Terry').to_a).to eq([])
    end

    sleep 0.25
    expect(Book.search('Harry').to_a).to eq([book])
  end

  it "marks core records as deleted" do
    book = Book.create :title => 'Night Watch', :author => 'Harry Pritchett'
    index

    expect(Book.search('Harry').to_a).to eq([book])

    ThinkingSphinx::Deltas.suspend_and_update :book do
      book.reload.update_attributes(:author => 'Terry Pratchett')
      sleep 0.25

      expect(Book.search('Terry').to_a).to eq([])
    end

    sleep 0.25
    expect(Book.search('Harry').to_a).to be_empty
  end
end
