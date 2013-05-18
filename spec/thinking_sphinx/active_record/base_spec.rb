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

  describe '.facets' do
    it "returns a new search object" do
      model.facets.should be_a(ThinkingSphinx::FacetSearch)
    end

    it "passes through arguments to the search object" do
      model.facets('pancakes').query.should == 'pancakes'
    end

    it "scopes the search to a given model" do
      model.facets('pancakes').options[:classes].should == [model]
    end

    it "merges the :classes option with the model" do
      model.facets('pancakes', :classes => [sub_model]).
        options[:classes].should == [sub_model, model]
    end

    it "applies the default scope if there is one" do
      model.stub :default_sphinx_scope => :default,
        :sphinx_scopes => {:default => Proc.new { {:order => :created_at} }}

      model.facets.options[:order].should == :created_at
    end

    it "does not apply a default scope if one is not set" do
      model.stub :default_sphinx_scope => nil,
        :default => {:order => :created_at}

      model.facets.options[:order].should be_nil
    end
  end

  describe '.search' do
    it "returns a new search object" do
      model.search.should be_a(ThinkingSphinx::Search)
    end

    it "passes through arguments to the search object" do
      model.search('pancakes').query.should == 'pancakes'
    end

    it "scopes the search to a given model" do
      model.search('pancakes').options[:classes].should == [model]
    end

    it "merges the :classes option with the model" do
      model.search('pancakes', :classes => [sub_model]).
        options[:classes].should == [sub_model, model]
    end

    it "applies the default scope if there is one" do
      model.stub :default_sphinx_scope => :default,
        :sphinx_scopes => {:default => Proc.new { {:order => :created_at} }}

      model.search.options[:order].should == :created_at
    end

    it "does not apply a default scope if one is not set" do
      model.stub :default_sphinx_scope => nil,
        :default => {:order => :created_at}

      model.search.options[:order].should be_nil
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
