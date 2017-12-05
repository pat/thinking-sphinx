# frozen_string_literal: true

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
      expect(model.facets).to be_a(ThinkingSphinx::FacetSearch)
    end

    it "passes through arguments to the search object" do
      expect(model.facets('pancakes').query).to eq('pancakes')
    end

    it "scopes the search to a given model" do
      expect(model.facets('pancakes').options[:classes]).to eq([model])
    end

    it "merges the :classes option with the model" do
      expect(model.facets('pancakes', :classes => [sub_model]).
        options[:classes]).to eq([sub_model, model])
    end

    it "applies the default scope if there is one" do
      allow(model).to receive_messages :default_sphinx_scope => :default,
        :sphinx_scopes => {:default => Proc.new { {:order => :created_at} }}

      expect(model.facets.options[:order]).to eq(:created_at)
    end

    it "does not apply a default scope if one is not set" do
      allow(model).to receive_messages :default_sphinx_scope => nil,
        :default => {:order => :created_at}

      expect(model.facets.options[:order]).to be_nil
    end
  end

  describe '.search' do
    let(:stack) { double('stack', :call => true) }

    before :each do
      stub_const 'ThinkingSphinx::Middlewares::DEFAULT', stack
    end

    it "returns a new search object" do
      expect(model.search).to be_a(ThinkingSphinx::Search)
    end

    it "passes through arguments to the search object" do
      expect(model.search('pancakes').query).to eq('pancakes')
    end

    it "scopes the search to a given model" do
      expect(model.search('pancakes').options[:classes]).to eq([model])
    end

    it "passes through options to the search object" do
      expect(model.search('pancakes', populate: true).
        options[:populate]).to be_truthy
    end

    it "should automatically populate when :populate is set to true" do
      expect(stack).to receive(:call).and_return(true)

      model.search('pancakes', populate: true)
    end

    it "merges the :classes option with the model" do
      expect(model.search('pancakes', :classes => [sub_model]).
        options[:classes]).to eq([sub_model, model])
    end

    it "respects provided middleware" do
      expect(model.search(:middleware => ThinkingSphinx::Middlewares::RAW_ONLY).
        options[:middleware]).to eq(ThinkingSphinx::Middlewares::RAW_ONLY)
    end

    it "respects provided masks" do
      expect(model.search(:masks => [ThinkingSphinx::Masks::PaginationMask]).
        masks).to eq([ThinkingSphinx::Masks::PaginationMask])
    end

    it "applies the default scope if there is one" do
      allow(model).to receive_messages :default_sphinx_scope => :default,
        :sphinx_scopes => {:default => Proc.new { {:order => :created_at} }}

      expect(model.search.options[:order]).to eq(:created_at)
    end

    it "does not apply a default scope if one is not set" do
      allow(model).to receive_messages :default_sphinx_scope => nil,
        :default => {:order => :created_at}

      expect(model.search.options[:order]).to be_nil
    end
  end

  describe '.search_count' do
    let(:search) { double('search', :options => {}, :total_entries => 12,
      :populated? => false) }

    before :each do
      allow(ThinkingSphinx).to receive_messages :search => search
      allow(FileUtils).to receive_messages :mkdir_p => true
    end

    it "returns the search object's total entries count" do
      expect(model.search_count).to eq(search.total_entries)
    end

    it "scopes the search to a given model" do
      model.search_count

      expect(search.options[:classes]).to eq([model])
    end
  end
end
