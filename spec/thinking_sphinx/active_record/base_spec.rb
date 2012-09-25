require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Base do
  let(:model) {
    Class.new(ActiveRecord::Base) do
      include ThinkingSphinx::ActiveRecord::Base

      def self.name; 'Model'; end
    end
  }
  let(:sub_model) {
    Class.new(model) do
      def self.name; 'SubModel'; end
    end
  }
  let(:search) { double('search', :options => {})}

  describe '.search' do
    before :each do
      ThinkingSphinx.stub :search => search
    end

    it "returns a new search object" do
      model.search.should == search
    end

    it "passes through arguments to the search object initializer" do
      ThinkingSphinx.should_receive(:search).with('pancakes', anything)

      model.search 'pancakes'
    end

    it "scopes the search to a given model" do
      model.search('pancakes').options[:classes].should == [model]
    end
    
    it "merges the :classes option with the model" do
      search_options = {:classes=>[sub_model]}
      search.stub :options => search_options
      model.search('pancakes', search_options).options[:classes].should == [sub_model, model]
    end
  end

  describe '.search_count' do
    let(:search) { double('search', :options => {}, :total_entries => 12) }

    before :each do
      ThinkingSphinx.stub :search => search
    end

    it "returns the search object's total entries count" do
      model.search_count.should == search.total_entries
    end

    it "scopes the search to a given model" do
      model.search_count

      search.options[:classes].should == [model]
    end
  end
end
