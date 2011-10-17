require 'spec_helper'

describe ThinkingSphinx::Search::Geodist do
  let(:config)       {
    double('config', :searchd => searchd, :indices_for_reference => [index],
      :indices => indices, :preload_indices => true)
  }
  let(:searchd)      { double('searchd', :address => nil, :mysql41 => 101) }
  let(:connection)   { double('connection') }
  let(:sphinx_sql)   {
    double('sphinx select', :to_sql => 'SELECT * FROM index')
  }
  let(:index)        { double('index', :name => 'article_core') }
  let(:indices)      { [index, double('index', :name => 'user_core')] }

  before :each do
    ThinkingSphinx::Configuration.stub! :instance => config
    Riddle::Query.stub! :connection => connection
    Riddle::Query::Select.stub! :new => sphinx_sql
    sphinx_sql.stub! :from => sphinx_sql, :offset => sphinx_sql,
      :limit => sphinx_sql

    connection.stub(:query).and_return([], [])
  end

  describe '#populate' do
    it "adds the geodist function when given a :geo option" do
      sphinx_sql.should_receive(:values).
        with('GEODIST(0.1, 0.2, lat, lng) AS geodist').
        and_return(sphinx_sql)

      ThinkingSphinx::Search.new('', :geo => [0.1, 0.2]).populate
    end

    it "doesn't add anything if :geo is nil" do
      sphinx_sql.should_not_receive(:values)

      ThinkingSphinx::Search.new.populate
    end
  end
end
