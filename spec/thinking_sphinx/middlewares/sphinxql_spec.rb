module ThinkingSphinx
  module Middlewares; end
end

module ActiveRecord
  class Base; end
end

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'
require 'thinking_sphinx/middlewares/middleware'
require 'thinking_sphinx/middlewares/sphinxql'

describe ThinkingSphinx::Middlewares::SphinxQL do
  let(:app)           { double('app', :call => true) }
  let(:middleware)    { ThinkingSphinx::Middlewares::SphinxQL.new app }
  let(:context)       { {} }
  let(:search)        { double('search', :query => '', :options => {},
    :offset => 0, :per_page => 5) }
  let(:configuration) { double('configuration', :preload_indices => true,
    :indices => [], :indices_for_references => []) }
  let(:sphinx_sql)    { double('sphinx_sql', :from => true, :offset => true,
    :limit => true, :where => true, :matching => true) }
  let(:query)         { double('query') }

  before :each do
    stub_const 'Riddle::Query::Select', double(:new => sphinx_sql)
    stub_const 'ThinkingSphinx::Search::Query', double(:new => query)
    stub_const 'ThinkingSphinx::Masks::GroupEnumeratorsMask', double

    context.stub :search => search, :configuration => configuration
  end

  describe '#call' do
    it "ensures the indices are loaded" do
      configuration.should_receive(:preload_indices)

      middleware.call [context]
    end

    it "uses all indices if not scoped to any models" do
      configuration.stub :indices => [
        double('index', :name => 'article_core'),
        double('index', :name => 'user_core')
      ]

      sphinx_sql.should_receive(:from).with('`article_core`', '`user_core`').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "uses indices for the given classes" do
      model = Class.new(ActiveRecord::Base) do
        def self.name; 'Article'; end
        def self.column_names; []; end
        def self.inheritance_column; 'type'; end
      end

      search.options[:classes] = [model]

      configuration.should_receive(:indices_for_references).with(:article).
        and_return([])

      middleware.call [context]
    end

    it "requests indices for any superclasses" do
      supermodel = Class.new(ActiveRecord::Base) do
        def self.name; 'Article'; end
        def self.column_names; []; end
        def self.inheritance_column; 'type'; end
      end
      submodel   = Class.new(supermodel) do
        def self.name; 'OpinionArticle'; end
        def self.column_names; []; end
        def self.inheritance_column; 'type'; end
      end

      search.options[:classes] = [submodel]

      configuration.should_receive(:indices_for_references).
        with(:opinion_article, :article).and_return([])

      middleware.call [context]
    end

    it "uses named indices if names are provided" do
      configuration.stub :indices => [
        double('index', :name => 'article_core'),
        double('index', :name => 'user_core')
      ]
      search.options[:indices] = ['article_core']

      sphinx_sql.should_receive(:from).with('`article_core`').
        and_return(sphinx_sql)

      middleware.call [context]
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

      search.options[:classes] = [submodel]

      ThinkingSphinx::Search::Query.should_receive(:new).with(anything,
        hash_including(:sphinx_internal_class => '(Lion)'), anything).
        and_return(query)

      middleware.call [context]
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

      sphinx_sql.should_receive(:group_by).with('foreign_id').
        and_return(sphinx_sql)

      middleware.call [context]
    end

    it "adds the group enumerator mask when using :group_by" do
      search.options[:group_by] = :foreign_id
      search.stub :masks => []
      sphinx_sql.stub :group_by => sphinx_sql

      middleware.call [context]

      search.masks.should include(ThinkingSphinx::Masks::GroupEnumeratorsMask)
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

    it "uses any provided field weights" do
      search.options[:field_weights] = {:title => 3}

      sphinx_sql.should_receive(:with_options) do |options|
        options[:field_weights].should == {:title => 3}
        sphinx_sql
      end

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
