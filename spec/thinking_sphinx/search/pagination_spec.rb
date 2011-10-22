require 'spec_helper'

describe ThinkingSphinx::Search::Pagination do
  let(:search)       { ThinkingSphinx::Search.new }
  let(:config)       {
    double('config', :searchd => searchd, :indices_for_reference => [index],
      :indices => indices, :preload_indices => true)
  }
  let(:searchd)      { double('searchd', :address => nil, :mysql41 => 101) }
  let(:connection)   { double('connection') }
  let(:meta_results) { [] }
  let(:sphinx_sql)   {
    double('sphinx select', :to_sql => 'SELECT * FROM index')
  }
  let(:model)        { double('model', :name => 'Article') }
  let(:index)        { double('index', :name => 'article_core') }
  let(:indices)      { [index, double('index', :name => 'user_core')] }

  before :each do
    ThinkingSphinx::Configuration.stub! :instance => config
    Riddle::Query.stub! :connection => connection
    Riddle::Query::Select.stub! :new => sphinx_sql
    sphinx_sql.stub! :from => sphinx_sql, :offset => sphinx_sql,
      :limit => sphinx_sql

    connection.stub(:query).and_return([], meta_results)
  end

  describe '#first_page?' do
    it "returns true when on the first page" do
      search.should be_first_page
    end

    it "returns false on other pages" do
      ThinkingSphinx::Search.new(:page => 2).should_not be_first_page
    end
  end

  describe '#last_page?' do
    let(:meta_results) { [{'Variable_name' => 'total', 'Value' => '44'}] }

    it "is true when there's no more pages" do
      ThinkingSphinx::Search.new(:page => 3).should be_last_page
    end

    it "is false when there's still more pages" do
      search.should_not be_last_page
    end
  end

  describe '#next_page' do
    let(:meta_results) { [{'Variable_name' => 'total', 'Value' => '44'}] }

    it "should return one more than the current page" do
      search.next_page.should == 2
    end

    it "should return nil if on the last page" do
      ThinkingSphinx::Search.new(:page => 3).next_page.should be_nil
    end
  end

  describe '#next_page?' do
    let(:meta_results) { [{'Variable_name' => 'total', 'Value' => '44'}] }

    it "is true when there is a second page" do
      search.next_page?.should be_true
    end

    it "is false when there's no more pages" do
      ThinkingSphinx::Search.new(:page => 3).next_page?.should be_false
    end
  end

  describe '#previous_page' do
    let(:meta_results) { [{'Variable_name' => 'total', 'Value' => '44'}] }

    it "should return one less than the current page" do
      ThinkingSphinx::Search.new(:page => 2).previous_page.should == 1
    end

    it "should return nil if on the first page" do
      search.previous_page.should be_nil
    end
  end

  describe '#total_entries' do
    let(:meta_results) { [{'Variable_name' => 'total_found', 'Value' => '12'}] }

    it "returns the total found from the search request metadata" do
      search.total_entries.should == 12
    end
  end

  describe '#total_pages' do
    let(:meta_results) { [
      {'Variable_name' => 'total',       'Value' => '40'},
      {'Variable_name' => 'total_found', 'Value' => '44'}
    ] }

    it "uses the total available from the search request metadata" do
      search.total_pages.should == 2
    end

    it "should allow for custom per_page values" do
      ThinkingSphinx::Search.new(:per_page => 40).total_pages.should == 1
    end

    it "should return 0 if there is no index and therefore no results" do
      meta_results.first['Value'] = nil

      search.total_pages.should == 0
    end
  end
end
