require 'spec_helper'

describe ThinkingSphinx::Search::Inquirer do
  let(:inquirer)   { ThinkingSphinx::Search::Inquirer.new search }
  let(:search)     {
    double('search', :query => '', :options => {}, :offset => 0, :per_page => 5)
  }
  let(:connection) { double('connection') }
  let(:sphinx_sql) { double('sphinx sql', :to_sql => 'SELECT * FROM index') }
  let(:config)     {
    double('config', :connection => connection, :preload_indices => true,
      :indices => [], :indices_for_references => [])
  }

  before :each do
    ThinkingSphinx::Configuration.stub :instance => config
    Riddle::Query.stub :connection => connection
    Riddle::Query::Select.stub :new => sphinx_sql

    connection.stub(:query).and_return([], [])
    sphinx_sql.stub :from => sphinx_sql, :offset => sphinx_sql,
      :limit => sphinx_sql, :where => sphinx_sql, :matching => sphinx_sql
  end

  describe '#populate' do
    it "returns itself" do
      inquirer.populate.should == inquirer
    end

    it "populates the data and meta sets from Sphinx" do
      connection.unstub :query
      connection.should_receive(:query).twice.and_return([], [])

      inquirer.populate
    end

    it "passes through the SphinxQL from a Riddle::Query::Select object" do
      connection.unstub :query
      connection.should_receive(:query).with('SELECT * FROM index').once.
        and_return([])
      connection.should_receive(:query).with('SHOW META').once.and_return([])

      inquirer.populate
    end

    it "ensures the indices are loaded" do
      config.should_receive(:preload_indices)

      inquirer.populate
    end

    it "uses all indices if not scoped to any models" do
      config.stub :indices => [
        double('index', :name => 'article_core'),
        double('index', :name => 'user_core')
      ]

      sphinx_sql.should_receive(:from).with('`article_core`', '`user_core`').
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "uses indices for the given classes" do
      model = Class.new(ActiveRecord::Base)
      model.stub :name => 'Article'

      search.options[:classes] = [model]

      config.should_receive(:indices_for_references).with(:article).
        and_return([])

      inquirer.populate
    end

    it "requests indices for any superclasses" do
      supermodel = Class.new(ActiveRecord::Base)
      supermodel.stub :name => 'Article'
      submodel   = Class.new(supermodel)
      submodel.stub :name => 'OpinionArticle'

      search.options[:classes] = [submodel]

      config.should_receive(:indices_for_references).
        with(:opinion_article, :article).and_return([])

      inquirer.populate
    end

    it "matches on the query given" do
      search.stub :query => 'pancakes'

      sphinx_sql.should_receive(:matching).with('pancakes').
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "appends field conditions to the query" do
      search.options[:conditions] = {:title => 'pancakes'}

      sphinx_sql.should_receive(:matching).with('@title pancakes').
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "appends field conditions for the class when searching on subclasses" do
      db_connection = double('db connection', :select_values => [])
      supermodel = Class.new(ActiveRecord::Base)
      supermodel.stub :name => 'Cat', :connection => db_connection,
        :column_names => ['type']
      submodel   = Class.new(supermodel)
      submodel.stub :name => 'Lion', :connection => db_connection,
        :column_names => ['type']

      search.options[:classes] = [submodel]

      sphinx_sql.should_receive(:matching).
        with('@sphinx_internal_class (Lion)').and_return(sphinx_sql)

      inquirer.populate
    end

    it "filters out deleted values by default" do
      sphinx_sql.should_receive(:where).with(:sphinx_deleted => false).
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "appends boolean attribute filters to the query" do
      search.options[:with] = {:visible => true}

      sphinx_sql.should_receive(:where).with(hash_including(:visible => true)).
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "appends exclusive filters to the query" do
      search.options[:without] = {:tag_ids => [2, 4, 8]}

      sphinx_sql.should_receive(:where_not).
        with(hash_including(:tag_ids => [2, 4, 8])).and_return(sphinx_sql)

      inquirer.populate
    end

    it "appends the without_ids option as an exclusive filter" do
      search.options[:without_ids] = [1, 4, 9]

      sphinx_sql.should_receive(:where_not).
        with(hash_including(:sphinx_internal_id => [1, 4, 9])).
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "appends order clauses to the query" do
      search.options[:order] = 'created_at ASC'

      sphinx_sql.should_receive(:order_by).with('created_at ASC').
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "presumes attributes given as symbols should be sorted ascendingly" do
      search.options[:order] = :updated_at

      sphinx_sql.should_receive(:order_by).with('updated_at ASC').
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "uses the provided offset" do
      search.stub :offset => 50

      sphinx_sql.should_receive(:offset).with(50).and_return(sphinx_sql)

      inquirer.populate
    end

    it "uses the provided limit" do
      search.stub :per_page => 24

      sphinx_sql.should_receive(:limit).with(24).and_return(sphinx_sql)

      inquirer.populate
    end

    it "adds the provided select statement" do
      search.options[:select] = 'foo as bar'

      sphinx_sql.should_receive(:values).with('foo as bar').
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "uses any provided field weights" do
      search.options[:field_weights] = {:title => 3}

      sphinx_sql.should_receive(:with_options) do |options|
        options[:field_weights].should == {:title => 3}
        sphinx_sql
      end

      inquirer.populate
    end

    it "uses any given ranker option" do
      search.options[:ranker] = 'proximity'

      sphinx_sql.should_receive(:with_options) do |options|
        options[:ranker].should == 'proximity'
        sphinx_sql
      end

      inquirer.populate
    end
  end
end
