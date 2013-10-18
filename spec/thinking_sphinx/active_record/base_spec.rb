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

    it "respects provided middleware" do
      model.search(:middleware => ThinkingSphinx::Middlewares::RAW_ONLY).
        options[:middleware].should == ThinkingSphinx::Middlewares::RAW_ONLY
    end

    it "respects provided masks" do
      model.search(:masks => [ThinkingSphinx::Masks::PaginationMask]).
        masks.should == [ThinkingSphinx::Masks::PaginationMask]
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

    it "raises an error on populate if no index has been defined for it" do
      lambda {
        model.search.to_a
      }.should raise_error ThinkingSphinx::MissingIndexError
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

  describe '.has_sphinx_indices?' do
    it "returns true if an index has been defined for the model" do
      ThinkingSphinx::Index.define :model, :with => :active_record
      model.has_sphinx_indices?.should be_true
      ThinkingSphinx::Configuration.instance.indices.clear
    end

    it "returns false if no index has been defined for the model" do
      model.has_sphinx_indices?.should be_false
    end
  end

  describe '.sphinx_index_names' do
    it "returns an array of strings of the model's index names" do
      ThinkingSphinx::Index.define :model,
        :with => :active_record,
        :name => "pancakes"

      ThinkingSphinx::Index.define :model,
        :with => :active_record,
        :name => "syrup"

      model.sphinx_index_names.should eq ["pancakes_core", "syrup_core"]
      ThinkingSphinx::Configuration.instance.indices.clear
    end

    it "returns an empty array if no index has been defined for the model" do
      model.sphinx_index_names.should eq []
    end
  end
end
