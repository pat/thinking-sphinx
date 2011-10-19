require 'spec_helper'

describe ThinkingSphinx::Search do
  let(:search)       { ThinkingSphinx::Search.new }
  let(:config)       {
    double('config', :searchd => searchd, :indices_for_reference => [index],
      :indices => indices, :preload_indices => true)
  }
  let(:searchd)      { double('searchd', :address => nil, :mysql41 => 101) }
  let(:connection)   { double('connection') }
  let(:results)      { [] }
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

    connection.stub(:query).and_return(results, meta_results)
  end

  describe '#current_page' do
    it "should return 1 by default" do
      search.current_page.should == 1
    end

    it "should handle string page values" do
      ThinkingSphinx::Search.new(:page => '2').current_page.should == 2
    end

    it "should handle empty string page values" do
      ThinkingSphinx::Search.new(:page => '').current_page.should == 1
    end

    it "should return the requested page" do
      ThinkingSphinx::Search.new(:page => 10).current_page.should == 10
    end
  end

  describe '#empty?' do
    it "returns false if there is anything in the data set" do
      instance   = double('instance', :id => 12)
      model      = double('model', :find => [instance])
      model_name = double('model name', :constantize => model)
      results << {
        'sphinx_internal_class' => model_name,
        'sphinx_internal_id' => 12
      }

      search.should_not be_empty
    end

    it "returns true if the data set is empty" do
      results.clear

      search.should be_empty
    end
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

  describe '#offset' do
    it "should default to 0" do
      search.offset.should == 0
    end

    it "should increase by the per_page value for each page in" do
      ThinkingSphinx::Search.new(:per_page => 25, :page => 2).offset.
        should == 25
    end

    it "should prioritise explicit :offset over calculated if given" do
      ThinkingSphinx::Search.new(:offset => 5).offset.should == 5
    end
  end

  describe '#page' do
    it "sets the current page" do
      search.page(3)
      search.current_page.should == 3
    end

    it "returns the search object" do
      search.page(2).should == search
    end
  end

  describe '#per' do
    it "sets the current per_page value" do
      search.per(29)
      search.per_page.should == 29
    end

    it "returns the search object" do
      search.per(29).should == search
    end
  end

  describe '#per_page' do
    it "defaults to 20" do
      search.per_page.should == 20
    end

    it "is set as part of the search options" do
      ThinkingSphinx::Search.new(:per_page => 10).per_page.should == 10
    end

    it "should prioritise :limit over :per_page if given" do
      ThinkingSphinx::Search.new(:per_page => 30, :limit => 40).per_page.
        should == 40
    end

    it "should allow for string arguments" do
      ThinkingSphinx::Search.new(:per_page => '10').per_page.should == 10
    end
  end

  describe '#populate' do
    it "populates the data set from Sphinx" do
      connection.unstub :query
      connection.should_receive(:query).once.and_return(results)

      search.populate
    end

    it "connects using the searchd address and port" do
      Riddle::Query.should_receive(:connection).with('127.0.0.1', 101).
        and_return(connection)

      search.populate
    end

    it "passes through the SphinxQL from a Riddle::Query::Select object" do
      connection.unstub :query
      connection.should_receive(:query).with('SELECT * FROM index').
        and_return(results)

      search.populate
    end

    it "ensures the indices are loaded" do
      config.should_receive(:preload_indices)

      search.populate
    end

    it "uses all indices if not scoped to any models" do
      sphinx_sql.should_receive(:from).with('`article_core`', '`user_core`').
        and_return(sphinx_sql)

      search.populate
    end

    it "uses indices for the given classes" do
      sphinx_sql.should_receive(:from).with('`article_core`').
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

    it "appends boolean attribute filters to the query" do
      sphinx_sql.should_receive(:where).with(:visible => true).
        and_return(sphinx_sql)

      ThinkingSphinx::Search.new(:with => {:visible => true}).populate
    end

    it "appends order clauses to the query" do
      sphinx_sql.should_receive(:order_by).with('created_at ASC').
        and_return(sphinx_sql)

      ThinkingSphinx::Search.new(:order => 'created_at ASC').populate
    end

    it "presumes attributes given as symbols should be sorted ascendingly" do
      sphinx_sql.should_receive(:order_by).with('updated_at ASC').
        and_return(sphinx_sql)

      ThinkingSphinx::Search.new(:order => :updated_at).populate
    end

    it "uses the provided offset" do
      sphinx_sql.should_receive(:offset).with(50).and_return(sphinx_sql)

      ThinkingSphinx::Search.new(:per_page => 25, :page => 3).populate
    end

    it "uses the provided limit" do
      sphinx_sql.should_receive(:limit).with(24).and_return(sphinx_sql)

      ThinkingSphinx::Search.new(:per_page => 24, :page => 3).populate
    end

    it "translates records to ActiveRecord objects" do
      model_name = double('article', :constantize => model)
      instance   = double('instance', :id => 24)
      connection.stub! :query => [
        {'sphinx_internal_id' => 24, 'sphinx_internal_class' => model_name}
      ]
      model.stub!(:find => [instance])

      search = ThinkingSphinx::Search.new('', :classes => [model])
      search.populate

      search.first.should == instance
    end

    it "only queries the model once for the given search results" do
      model_name = double('article', :constantize => model)
      instance   = double('instance', :id => 24)
      connection.stub! :query => [
        {'sphinx_internal_id' => 24, 'sphinx_internal_class' => model_name},
        {'sphinx_internal_id' => 42, 'sphinx_internal_class' => model_name}
      ]

      model.should_receive(:find).once.and_return([instance])

      search = ThinkingSphinx::Search.new('', :classes => [model])
      search.populate
    end

    it "handles multiple models" do
      article_model = double('article model')
      article_name  = double('article name', :constantize => article_model)
      article       = double('article instance', :id => 24)

      user_model    = double('user model')
      user_name     = double('user name', :constantize => user_model)
      user          = double('user instance', :id => 12)

      connection.stub! :query => [
        {'sphinx_internal_id' => 24, 'sphinx_internal_class' => article_name},
        {'sphinx_internal_id' => 12, 'sphinx_internal_class' => user_name}
      ]

      article_model.should_receive(:find).once.and_return([article])
      user_model.should_receive(:find).once.and_return([user])

      search.populate
    end

    it "sorts the results according to Sphinx order, not database order" do
      model_name = double('article', :constantize => model)
      instance_1 = double('instance 1', :id => 1)
      instance_2 = double('instance 1', :id => 2)
      connection.stub! :query => [
        {'sphinx_internal_id' => 2, 'sphinx_internal_class' => model_name},
        {'sphinx_internal_id' => 1, 'sphinx_internal_class' => model_name}
      ]

      model.stub(:find => [instance_1, instance_2])

      search.populate
      search.to_a.should == [instance_2, instance_1]
    end

    it "should automatically populate when :populate is set to true" do
      connection.unstub :query
      connection.should_receive(:query).once.and_return(results)

      ThinkingSphinx::Search.new(:populate => true)
    end

    it "returns itself" do
      search.populate.should == search
    end
  end

  describe '#populate_meta' do
    it "connects using the searchd address and port" do
      Riddle::Query.should_receive(:connection).with('127.0.0.1', 101).
        and_return(connection)

      search.populate_meta
    end

    it "requests the query and the metadata from Sphinx" do
      connection.unstub :query
      connection.should_receive(:query).with('SELECT * FROM index').once.
        and_return(results)
      connection.should_receive(:query).with('SHOW META').once.
        and_return(meta_results)

      search.populate_meta
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

  describe '#respond_to?' do
    it "should respond to Array methods" do
      search.respond_to?(:each).should be_true
    end

    it "should respond to Search methods" do
      search.respond_to?(:per_page).should be_true
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
