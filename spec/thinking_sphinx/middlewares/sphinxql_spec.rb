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
require 'thinking_sphinx/sphinxql'

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
  let(:configuration) { double('configuration', :settings => {}) }

  before :each do
    stub_const 'Riddle::Query::Select', double(:new => sphinx_sql)
    stub_const 'ThinkingSphinx::Search::Query', double(:new => query)
    stub_const 'ThinkingSphinx::IndexSet', double(:new => index_set)

    context.stub :search => search, :configuration => configuration
  end

  describe '#call' do
    it "uses the indexes for the FROM clause" do
      index_set.replace [
        double('index', :name => 'article_core', :options => {}),
        double('index', :name => 'user_core', :options => {})
      ]

      sphinx_sql.should_receive(:from).with('`article_core`', '`user_core`').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "finds index objects for the given models and indices options" do
      klass = double(:column_names => [], :inheritance_column => 'type',
        :name => 'User')
      search.options[:classes] = [klass]
      search.options[:indices] = ['user_core']
      index_set.first.stub :reference => :user

      ThinkingSphinx::IndexSet.should_receive(:new).
        with([klass], ['user_core']).and_return(index_set)

      middleware.call [context]
    end

    it "raises an exception if there's no matching indices" do
      index_set.clear

      expect {
        middleware.call [context]
      }.to raise_error(ThinkingSphinx::NoIndicesError)
    end

    it "generates a Sphinx query from the provided keyword and conditions" do
      search.stub :query => 'tasty'
      search.options[:conditions] = {:title => 'pancakes'}

      ThinkingSphinx::Search::Query.should_receive(:new).
        with('tasty', {:title => 'pancakes'}, anything).and_return(query)

      middleware.call [context]
    end

    it "matches on the generated query" do
      query.stub :to_s => 'waffles'

      sphinx_sql.should_receive(:matching).with('waffles')

      middleware.call [context]
    end

    it "requests a starred query if the :star option is set to true" do
      search.options[:star] = true

      ThinkingSphinx::Search::Query.should_receive(:new).
        with(anything, anything, true).and_return(query)

      middleware.call [context]
    end

    it "doesn't append a field condition by default" do
      ThinkingSphinx::Search::Query.should_receive(:new) do |query, conditions, star|
        conditions[:sphinx_internal_class_name].should be_nil
        query
      end

      middleware.call [context]
    end

    it "doesn't append a field condition if all classes match index references" do
      model = double('model', :connection => double,
        :ancestors => [ActiveRecord::Base], :name => 'Animal')
      index_set.first.stub :reference => :animal

      search.options[:classes] = [model]

      ThinkingSphinx::Search::Query.should_receive(:new) do |query, conditions, star|
        conditions[:sphinx_internal_class_name].should be_nil
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
      supermodel.stub :connection => db_connection, :column_names => ['type']
      submodel   = Class.new(supermodel) do
        def self.name; 'Lion'; end
        def self.inheritance_column; 'type'; end
        def self.table_name; 'cats'; end
      end
      submodel.stub :connection => db_connection, :column_names => ['type'],
        :descendants => []
      index_set.first.stub :reference => :cat

      search.options[:classes] = [submodel]

      ThinkingSphinx::Search::Query.should_receive(:new).with(anything,
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
      supermodel.stub :connection => db_connection, :column_names => ['type']
      submodel   = Class.new(supermodel) do
        def self.name; 'Animals::Lion'; end
        def self.inheritance_column; 'type'; end
        def self.table_name; 'cats'; end
      end
      submodel.stub :connection => db_connection, :column_names => ['type'],
        :descendants => []
      index_set.first.stub :reference => :"animals/cat"

      search.options[:classes] = [submodel]

      ThinkingSphinx::Search::Query.should_receive(:new).with(anything,
        hash_including(:sphinx_internal_class_name => '("Animals::Lion")'), anything).
        and_return(query)

      middleware.call [context]
    end

    it "does not query the database for subclasses if :skip_sti is set to true" do
      model = double('model', :connection => double,
        :ancestors => [ActiveRecord::Base], :name => 'Animal')
      index_set.first.stub :reference => :animal

      search.options[:classes]  = [model]
      search.options[:skip_sti] = true

      model.connection.should_not_receive(:select_values)

      middleware.call [context]
    end

    it "ignores blank subclasses" do
      db_connection = double('db connection', :select_values => [''],
        :schema_cache => double('cache', :table_exists? => false))
      supermodel = Class.new(ActiveRecord::Base) do
        def self.name; 'Cat'; end
        def self.inheritance_column; 'type'; end
      end
      supermodel.stub :connection => db_connection, :column_names => ['type']
      submodel   = Class.new(supermodel) do
        def self.name; 'Lion'; end
        def self.inheritance_column; 'type'; end
        def self.table_name; 'cats'; end
      end
      submodel.stub :connection => db_connection, :column_names => ['type'],
        :descendants => []
      index_set.first.stub :reference => :cat

      search.options[:classes] = [submodel]

      expect { middleware.call [context] }.to_not raise_error
    end

    it "filters out deleted values by default" do
      sphinx_sql.should_receive(:where).with(:sphinx_deleted => false).
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends boolean attribute filters to the query" do
      search.options[:with] = {:visible => true}

      sphinx_sql.should_receive(:where).with(hash_including(:visible => true)).
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends exclusive filters to the query" do
      search.options[:without] = {:tag_ids => [2, 4, 8]}

      sphinx_sql.should_receive(:where_not).
        with(hash_including(:tag_ids => [2, 4, 8])).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends the without_ids option as an exclusive filter" do
      search.options[:without_ids] = [1, 4, 9]

      sphinx_sql.should_receive(:where_not).
        with(hash_including(:sphinx_internal_id => [1, 4, 9])).
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends MVA matches with all values" do
      search.options[:with_all] = {:tag_ids => [1, 7]}

      sphinx_sql.should_receive(:where_all).
        with(:tag_ids => [1, 7]).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends MVA matches without all of the given values" do
      search.options[:without_all] = {:tag_ids => [1, 7]}

      sphinx_sql.should_receive(:where_not_all).
        with(:tag_ids => [1, 7]).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends order clauses to the query" do
      search.options[:order] = 'created_at ASC'

      sphinx_sql.should_receive(:order_by).with('created_at ASC').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "presumes attributes given as symbols should be sorted ascendingly" do
      search.options[:order] = :updated_at

      sphinx_sql.should_receive(:order_by).with('updated_at ASC').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends a group by clause to the query" do
      search.options[:group_by] = :foreign_id
      search.stub :masks => []
      sphinx_sql.stub :values => sphinx_sql

      sphinx_sql.should_receive(:group_by).with('foreign_id').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "appends a sort within group clause to the query" do
      search.options[:order_group_by] = :title

      sphinx_sql.should_receive(:order_within_group_by).with('title ASC').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses the provided offset" do
      search.stub :offset => 50

      sphinx_sql.should_receive(:offset).with(50).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses the provided limit" do
      search.stub :per_page => 24

      sphinx_sql.should_receive(:limit).with(24).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "adds the provided select statement" do
      search.options[:select] = 'foo as bar'

      sphinx_sql.should_receive(:values).with('foo as bar').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "adds the provided group-best count" do
      search.options[:group_best] = 5

      sphinx_sql.should_receive(:group_best).with(5).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "adds the provided having clause" do
      search.options[:having] = 'foo > 1'

      sphinx_sql.should_receive(:having).with('foo > 1').and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses any provided field weights" do
      search.options[:field_weights] = {:title => 3}

      sphinx_sql.should_receive(:with_options) do |options|
        options[:field_weights].should == {:title => 3}
        sphinx_sql
      end

      middleware.call [context]
    end

    it "uses index-defined field weights if they're available" do
      index_set.first.options[:field_weights] = {:title => 3}

      sphinx_sql.should_receive(:with_options).with(
        hash_including(:field_weights => {:title => 3})
      ).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses index-defined max matches if it's available" do
      index_set.first.options[:max_matches] = 100

      sphinx_sql.should_receive(:with_options).with(
        hash_including(:max_matches => 100)
      ).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses configuration-level max matches if set" do
      configuration.settings['max_matches'] = 120

      sphinx_sql.should_receive(:with_options).with(
        hash_including(:max_matches => 120)
      ).and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses any given ranker option" do
      search.options[:ranker] = 'proximity'

      sphinx_sql.should_receive(:with_options) do |options|
        options[:ranker].should == 'proximity'
        sphinx_sql
      end

      middleware.call [context]
    end
  end
end
