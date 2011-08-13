require 'spec_helper'

describe ThinkingSphinx::Search do
  describe '#empty?' do
    let(:search)     { ThinkingSphinx::Search.new }
    let(:connection) { double('connection', :query => results) }
    let(:results)    { double('results', :collect => []) }

    before :each do
      Riddle::Query.stub! :connection => connection
    end

    it "populates the data set from Sphinx" do
      connection.should_receive(:query).and_return(results)

      search.empty?
    end

    it "returns false if there is anything in the data set" do
      results.stub!(:collect => [{}])

      search.should_not be_empty
    end

    it "returns true if the data set is empty" do
      results.stub!(:collect => [])

      search.should be_empty
    end
  end
end
