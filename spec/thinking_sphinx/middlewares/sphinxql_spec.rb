# frozen_string_literal: true

module ThinkingSphinx
  module Middlewares; end
end

module ActiveRecord
  class Base; end
end

class SphinxQLSubclass
end

require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'
require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/sphinxql'
require 'thinking_sphinx/errors'

describe ThinkingSphinx::Middlewares::SphinxQL do
  let(:app)           { double('app', :call => true) }
  let(:middleware)    { ThinkingSphinx::Middlewares::SphinxQL.new app }
  let(:context)       { {} }
  let(:search)        { double('search', :query => '', :options => {},
    :offset => 0, :per_page => 5) }
  let(:index_set)     { [double(:name => 'article_core', :options => {})] }
  let(:sphinx_sql)    { double('sphinx_sql', :from => true, :offset => true,
    :limit => true, :where => true, :matching => true, :values => true) }
  let(:query)         { double('query') }
  let(:configuration) { double('configuration', :settings => {},
    index_set_class: set_class) }
  let(:set_class)     { double(:new => index_set) }

  before :each do
    stub_const 'Riddle::Query::Select', double(:new => sphinx_sql)
    stub_const 'ThinkingSphinx::Search::Query', double(:new => query)

    allow(context).to receive_messages :search => search, :configuration => configuration
  end

  describe '#call' do
    it "uses the indexes for the FROM clause" do
      index_set.replace [
        double('index', :name => 'article_core', :options => {}),
        double('index', :name => 'user_core', :options => {})
      ]

      expect(sphinx_sql).to receive(:from).with('`article_core`', '`user_core`').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "finds index objects for the given models and indices options" do
      klass = double(:column_names => [], :inheritance_column => 'type',
        :name => 'User')
      search.options[:classes] = [klass]
      search.options[:indices] = ['user_core']
      allow(index_set.first).to receive_messages :reference => :user

      expect(set_class).to receive(:new).
        with(:classes => [klass], :indices => ['user_core']).
        and_return(index_set)

      middleware.call [context]
    end

    it "raises an exception if there's no matching indices" do
      index_set.clear

      expect {
        middleware.call [context]
      }.to raise_error(ThinkingSphinx::NoIndicesError)
    end

    it "generates a Sphinx query from the provided keyword and conditions" do
      allow(search).to receive_messages :query => 'tasty'
      search.options[:conditions] = {:title => 'pancakes'}

      expect(ThinkingSphinx::Search::Query).to receive(:new).
        with('tasty', {:title => 'pancakes'}, anything).and_return(query)

      middleware.call [context]
    end

    it "matches on the generated query" do
      allow(query).to receive_messages :to_s => 'waffles'

      expect(sphinx_sql).to receive(:matching).with('waffles')

      middleware.call [context]
    end

    it "requests a starred query if the :star option is set to true" do
      search.options[:star] = true

      expect(ThinkingSphinx::Search::Query).to receive(:new).
        with(anything, anything, true).and_return(query)

      middleware.call [context]
    end

    it "doesn't append a field condition by default" do
      expect(ThinkingSphinx::Search::Query).to receive(:new) do |query, conditions, star|
        expect(conditions[:sphinx_internal_class_name]).to be_nil
        query
      end

      middleware.call [context]
    end

    it "doesn't append a field condition if all classes match index references" do
      model = double('model', :connection => double,
        :ancestors => [ActiveRecord::Base], :name => 'Animal')
      allow(index_set.first).to receive_messages :reference => :animal

      search.options[:classes] = [model]

      expect(ThinkingSphinx::Search::Query).to receive(:new) do |query, conditions, star|
        expect(conditions[:sphinx_internal_class_name]).to be_nil
        query
      end

      middleware.call [context]
    end

    it "appends field conditions for the class when searching on subclasses" do
      db_connection = double('db connection', :select_values => [],
        :schema_cache => double('cache', :table_exists? => false))
      supermodel = Class.new(ActiveRecord::Base) do
        def self.name; 'Cat'; end
        def self.inheritance_column; 'type'; end
      end
      allow(supermodel).to receive_messages :connection => db_connection, :column_names => ['type']
      submodel   = Class.new(supermodel) do
        def self.name; 'Lion'; end
        def self.inheritance_column; 'type'; end
        def self.table_name; 'cats'; end
      end
      allow(submodel).to receive_messages :connection => db_connection, :column_names => ['type'],
        :descendants => []
      allow(index_set.first).to receive_messages :reference => :cat

      search.options[:classes] = [submodel]

      expect(ThinkingSphinx::Search::Query).to receive(:new).with(anything,
        hash_including(:sphinx_internal_class_name => '(Lion)'), anything).
        and_return(query)

      middleware.call [context]
    end

    it "quotes namespaced models in the class name condition" do
      db_connection = double('db connection', :select_values => [],
        :schema_cache => double('cache', :table_exists? => false))
      supermodel = Class.new(ActiveRecord::Base) do
        def self.name; 'Animals::Cat'; end
        def self.inheritance_column; 'type'; end
      end
      allow(supermodel).to receive_messages :connection => db_connection, :column_names => ['type']
      submodel   = Class.new(supermodel) do
        def self.name; 'Animals::Lion'; end
        def self.inheritance_column; 'type'; end
        def self.table_name; 'cats'; end
      end
      allow(submodel).to receive_messages :connection => db_connection, :column_names => ['type'],
        :descendants => []
      allow(index_set.first).to receive_messages :reference => :"animals/cat"

      search.options[:classes] = [submodel]

      expect(ThinkingSphinx::Search::Query).to receive(:new).with(anything,
        hash_including(:sphinx_internal_class_name => '("Animals::Lion")'), anything).
        and_return(query)

      middleware.call [context]
    end

    it "does not query the database for subclasses if :skip_sti is set to true" do
      model = double('model', :connection => double,
        :ancestors => [ActiveRecord::Base], :name => 'Animal')
      allow(index_set.first).to receive_messages :reference => :animal

      search.options[:classes]  = [model]
      search.options[:skip_sti] = true

      expect(model.connection).not_to receive(:select_values)

      middleware.call [context]
    end

    it "ignores blank subclasses" do
      db_connection = double('db connection', :select_values => [''],
        :schema_cache => double('cache', :table_exists? => false))
      supermodel = Class.new(ActiveRecord::Base) do
        def self.name; 'Cat'; end
        def self.inheritance_column; 'type'; end
      end
      allow(supermodel).to receive_messages :connection => db_connection, :column_names => ['type']
      submodel   = Class.new(supermodel) do
        def self.name; 'Lion'; end
        def self.inheritance_column; 'type'; end
        def self.table_name; 'cats'; end
      end
      allow(submodel).to receive_messages :connection => db_connection, :column_names => ['type'],
        :descendants => []
      allow(index_set.first).to receive_messages :reference => :cat

      search.options[:classes] = [submodel]

      expect { middleware.call [context] }.to_not raise_error
    end

    it "filters out deleted values by default" do
      expect(sphinx_sql).to receive(:where).with(:sphinx_deleted => false).
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends boolean attribute filters to the query" do
      search.options[:with] = {:visible => true}

      expect(sphinx_sql).to receive(:where).with(hash_including(:visible => true)).
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends exclusive filters to the query" do
      search.options[:without] = {:tag_ids => [2, 4, 8]}

      expect(sphinx_sql).to receive(:where_not).
        with(hash_including(:tag_ids => [2, 4, 8])).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends the without_ids option as an exclusive filter" do
      search.options[:without_ids] = [1, 4, 9]

      expect(sphinx_sql).to receive(:where_not).
        with(hash_including(:sphinx_internal_id => [1, 4, 9])).
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends MVA matches with all values" do
      search.options[:with_all] = {:tag_ids => [1, 7]}

      expect(sphinx_sql).to receive(:where_all).
        with(:tag_ids => [1, 7]).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends MVA matches without all of the given values" do
      search.options[:without_all] = {:tag_ids => [1, 7]}

      expect(sphinx_sql).to receive(:where_not_all).
        with(:tag_ids => [1, 7]).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends order clauses to the query" do
      search.options[:order] = 'created_at ASC'

      expect(sphinx_sql).to receive(:order_by).with('created_at ASC').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "presumes attributes given as symbols should be sorted ascendingly" do
      search.options[:order] = :updated_at

      expect(sphinx_sql).to receive(:order_by).with('updated_at ASC').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends a group by clause to the query" do
      search.options[:group_by] = :foreign_id
      allow(search).to receive_messages :masks => []
      allow(sphinx_sql).to receive_messages :values => sphinx_sql

      expect(sphinx_sql).to receive(:group_by).with('foreign_id').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends a sort within group clause to the query" do
      search.options[:order_group_by] = :title

      expect(sphinx_sql).to receive(:order_within_group_by).with('title ASC').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses the provided offset" do
      allow(search).to receive_messages :offset => 50

      expect(sphinx_sql).to receive(:offset).with(50).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses the provided limit" do
      allow(search).to receive_messages :per_page => 24

      expect(sphinx_sql).to receive(:limit).with(24).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "adds the provided select statement" do
      search.options[:select] = 'foo as bar'

      expect(sphinx_sql).to receive(:values).with('foo as bar').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "adds the provided group-best count" do
      search.options[:group_best] = 5

      expect(sphinx_sql).to receive(:group_best).with(5).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "adds the provided having clause" do
      search.options[:having] = 'foo > 1'

      expect(sphinx_sql).to receive(:having).with('foo > 1').and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses any provided field weights" do
      search.options[:field_weights] = {:title => 3}

      expect(sphinx_sql).to receive(:with_options) do |options|
        expect(options[:field_weights]).to eq({:title => 3})
        sphinx_sql
      end

      middleware.call [context]
    end

    it "uses index-defined field weights if they're available" do
      index_set.first.options[:field_weights] = {:title => 3}

      expect(sphinx_sql).to receive(:with_options).with(
        hash_including(:field_weights => {:title => 3})
      ).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses index-defined max matches if it's available" do
      index_set.first.options[:max_matches] = 100

      expect(sphinx_sql).to receive(:with_options).with(
        hash_including(:max_matches => 100)
      ).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses configuration-level max matches if set" do
      configuration.settings['max_matches'] = 120

      expect(sphinx_sql).to receive(:with_options).with(
        hash_including(:max_matches => 120)
      ).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses any given ranker option" do
      search.options[:ranker] = 'proximity'

      expect(sphinx_sql).to receive(:with_options) do |options|
        expect(options[:ranker]).to eq('proximity')
        sphinx_sql
      end

      middleware.call [context]
    end
  end
end
