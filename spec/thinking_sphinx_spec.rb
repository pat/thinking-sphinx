require 'spec_helper'

describe ThinkingSphinx do
  describe '.count' do
    let(:search) { double('search', :total_entries => 23, :populated? => false,
      :options => {}) }

    before :each do
      ThinkingSphinx::Search.stub :new => search
    end

    it "returns the total entries of the search object" do
      ThinkingSphinx.count.should == search.total_entries
    end

    it "passes through the given query and options" do
      ThinkingSphinx::Search.should_receive(:new).with('foo', :bar => :baz).
        and_return(search)

      ThinkingSphinx.count('foo', :bar => :baz)
    end
  end

  describe '.search' do
    let(:search) { double('search') }

    before :each do
      ThinkingSphinx::Search.stub :new => search
    end

    it "returns a new search object" do
      ThinkingSphinx.search.should == search
    end

    it "passes through the given query and options" do
      ThinkingSphinx::Search.should_receive(:new).with('foo', :bar => :baz).
        and_return(search)

      ThinkingSphinx.search('foo', :bar => :baz)
    end
  end
end
