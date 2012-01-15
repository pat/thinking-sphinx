require 'spec_helper'

describe ThinkingSphinx::Search::Geodist do
  let(:inquirer)   { ThinkingSphinx::Search::Inquirer.new search }
  let(:search)     {
    double('search', :query => '', :options => {}, :offset => 0, :per_page => 5)
  }
  let(:config)     {
    double('config', :connection => connection, :indices => [],
      :preload_indices => true)
  }
  let(:connection) { double('connection') }
  let(:sphinx_sql) { double('sphinx select', :to_sql => '') }

  before :each do
    ThinkingSphinx::Configuration.stub! :instance => config
    Riddle::Query.stub! :connection => connection
    Riddle::Query::Select.stub! :new => sphinx_sql

    sphinx_sql.stub! :from => sphinx_sql, :offset => sphinx_sql,
      :limit => sphinx_sql, :where => sphinx_sql
    connection.stub(:query).and_return([], [])
  end

  describe '#populate' do
    it "adds the geodist function when given a :geo option" do
      search.options[:geo] = [0.1, 0.2]

      sphinx_sql.should_receive(:values).
        with('GEODIST(0.1, 0.2, lat, lng) AS geodist').
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "doesn't add anything if :geo is nil" do
      search.options[:geo] = nil

      sphinx_sql.should_not_receive(:values)

      inquirer.populate
    end

    it "respects :latitude_attr and :longitude_attr options" do
      search.options[:latitude_attr]  = 'side_to_side'
      search.options[:longitude_attr] = 'up_or_down'
      search.options[:geo] = [0.1, 0.2]

      sphinx_sql.should_receive(:values).
        with('GEODIST(0.1, 0.2, side_to_side, up_or_down) AS geodist').
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "uses latitude if any index has that but not lat as an attribute" do
      config.indices << double('index', :unique_attribute_names => ['latitude'],
        :name => 'an_index')
      search.options[:geo] = [0.1, 0.2]

      sphinx_sql.should_receive(:values).
        with('GEODIST(0.1, 0.2, latitude, lng) AS geodist').
        and_return(sphinx_sql)

      inquirer.populate
    end

    it "uses latitude if any index has that but not lat as an attribute" do
      config.indices << double('index',
        :unique_attribute_names => ['longitude'], :name => 'an_index')
      search.options[:geo] = [0.1, 0.2]

      sphinx_sql.should_receive(:values).
        with('GEODIST(0.1, 0.2, lat, longitude) AS geodist').
        and_return(sphinx_sql)

      inquirer.populate
    end
  end
end
