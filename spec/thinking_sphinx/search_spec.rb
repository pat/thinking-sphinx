require 'spec_helper'

describe ThinkingSphinx::Search do
  let(:search)     { ThinkingSphinx::Search.new }
  let(:config)     {
    double('config', :searchd => searchd, :indices_for_reference => [index],
      :indexes => indices)
  }
  let(:searchd)    { double('searchd', :address => nil, :mysql41 => 101) }
  let(:connection) { double('connection', :query => results) }
  let(:results)    { double('results', :collect => []) }
  let(:sphinx_sql) { double('sphinx select', :to_sql => 'SELECT * FROM index') }
  let(:model)      { double('model', :name => 'Article') }
  let(:index)      { double('index', :name => 'article_core') }
  let(:indices)    { [index, double('index', :name => 'user_core')] }

  before :each do
    ThinkingSphinx::Configuration.stub! :instance => config
    Riddle::Query.stub! :connection => connection
    Riddle::Query::Select.stub! :new => sphinx_sql
    sphinx_sql.stub! :from => sphinx_sql
  end

  describe '#empty?' do
    it "returns false if there is anything in the data set" do
      results.stub!(:collect => [{}])

      search.should_not be_empty
    end

    it "returns true if the data set is empty" do
      results.stub!(:collect => [])

      search.should be_empty
    end
  end

  describe '#populate' do
    it "populates the data set from Sphinx" do
      connection.should_receive(:query).and_return(results)

      search.populate
    end

    it "connects using the searchd address and port" do
      Riddle::Query.should_receive(:connection).with('127.0.0.1', 101).
        and_return(connection)

      search.populate
    end

    it "passes through the SphinxQL from a Riddle::Query::Select object" do
      connection.should_receive(:query).with('SELECT * FROM index').
        and_return(results)

      search.populate
    end

    it "uses all indices if not scoped to any models" do
      sphinx_sql.should_receive(:from).with('article_core', 'user_core').
        and_return(sphinx_sql)

      search.populate
    end

    it "uses indices for the given classes" do
      sphinx_sql.should_receive(:from).with('article_core').
        and_return(sphinx_sql)

      ThinkingSphinx::Search.new('', :classes => [model]).populate
    end

    it "matches on the query given" do
      sphinx_sql.should_receive(:matching).with('pancakes').
        and_return(sphinx_sql)

      ThinkingSphinx::Search.new('pancakes').populate
    end

    it "appends field conditions to the query" do
      sphinx_sql.should_receive(:matching).with('@title pancakes').
        and_return(sphinx_sql)

      ThinkingSphinx::Search.new(:conditions => {:title => 'pancakes'}).populate
    end

    it "translates records to ActiveRecord objects" do
      model_name = double('article', :constantize => model)
      instance   = double('instance')
      connection.stub! :query => [
        {'sphinx_internal_id' => 24, 'sphinx_internal_class' => model_name}
      ]
      model.stub!(:find => instance)

      search = ThinkingSphinx::Search.new('', :classes => [model])
      search.populate

      search.first.should == instance
    end
  end
end
