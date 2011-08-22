require 'spec_helper'

describe ThinkingSphinx::ActiveRecord::Scopes do
  after :each do
    Alpha.remove_sphinx_scopes
  end

  it "should be included into models with indexes" do
    Alpha.included_modules.should include(ThinkingSphinx::ActiveRecord::Scopes)
  end

  it "should not be included into models without indexes" do
    Gamma.included_modules.should_not include(
      ThinkingSphinx::ActiveRecord::Scopes
    )
  end

  describe '.sphinx_scope' do
    before :each do
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
    end

    it "should define a method on the model" do
      Alpha.should respond_to(:by_name)
    end
  end

  describe '.sphinx_scopes' do
    before :each do
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
    end

    it "should return an array of defined scope names as symbols" do
      Alpha.sphinx_scopes.should == [:by_name]
    end
  end

  describe '.default_sphinx_scope' do
    before :each do
      Alpha.sphinx_scope(:scope_used_as_default_scope) { {:conditions => {:name => 'name'}} }
      Alpha.default_sphinx_scope :scope_used_as_default_scope
    end

    it "should return an array of defined scope names as symbols" do
      Alpha.sphinx_scopes.should == [:scope_used_as_default_scope]
    end

    it "should have a default_sphinx_scope" do
      Alpha.has_default_sphinx_scope?.should be_true
    end
  end

  describe '.remove_sphinx_scopes' do
    before :each do
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
      Alpha.remove_sphinx_scopes
    end

    it "should remove sphinx scope methods" do
      Alpha.should_not respond_to(:by_name)
    end

    it "should empty the list of sphinx scopes" do
      Alpha.sphinx_scopes.should be_empty
    end
  end

  describe '.example_default_scope' do
    before :each do
      Alpha.sphinx_scope(:foo_scope){ {:conditions => {:name => 'foo'}} }
      Alpha.default_sphinx_scope :foo_scope
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
      Alpha.sphinx_scope(:by_foo)  { |foo|  {:conditions => {:foo  => foo}}  }
    end

    it "should return a ThinkingSphinx::Search object" do
      Alpha.search.should be_a(ThinkingSphinx::Search)
    end

    it "should apply the default scope options to the underlying search object" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.search.options[:conditions].should == {:name => 'foo'}
    end

    it "should apply the default scope options and scope options to the underlying search object" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_foo('foo').search.options[:conditions].should == {:foo => 'foo', :name => 'foo'}
    end

    it "should apply the default scope options before other scope options to the underlying search object" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_name('bar').search.options[:conditions].should == {:name => 'bar'}
    end
  end

  describe '.example_scope' do
    before :each do
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
      Alpha.sphinx_scope(:by_foo)  { |foo|  {:conditions => {:foo  => foo}}  }
      Alpha.sphinx_scope(:with_betas) { {:classes => [Beta]} }
    end

    it "should return a ThinkingSphinx::Search object" do
      Alpha.by_name('foo').should be_a(ThinkingSphinx::Search)
    end

    it "should set the classes option" do
      Alpha.by_name('foo').options[:classes].should == [Alpha]
    end

    it "should be able to be called on a ThinkingSphinx::Search object" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      lambda {
        search.by_name('foo')
      }.should_not raise_error
    end

    it "should return the search object it gets called upon" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_name('foo').object_id.should == search.object_id
    end

    it "should apply the scope options to the underlying search object" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_name('foo').options[:conditions].should == {:name => 'foo'}
    end

    it "should combine hash option scopes such as :conditions" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_name('foo').by_foo('bar').options[:conditions].
        should == {:name => 'foo', :foo => 'bar'}
    end

    it "should combine array option scopes such as :classes" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.with_betas.options[:classes].should == [Alpha, Beta]
    end
  end

  describe '.search_count_with_scope' do
    before :each do
      @config = ThinkingSphinx::Configuration.instance
      @client = Riddle::Client.new

      @config.stub!(:client => @client)
      @client.stub!(:query => {:matches => [], :total_found => 43})
      Alpha.sphinx_scope(:by_name) { |name| {:conditions => {:name => name}} }
      Alpha.sphinx_scope(:ids_only) { {:ids_only => true} }
    end

    it "should return the total number of results" do
      Alpha.by_name('foo').search_count.should == 43
    end

    it "should not make any calls to the database" do
      Alpha.should_not_receive(:find)

      Alpha.by_name('foo').search_count
    end

    it "should not leave the :ids_only option set and the results populated if it was not set before" do
      stored_scope = Alpha.by_name('foo')
      stored_scope.search_count
      stored_scope.options[:ids_only].should be_false
      stored_scope.populated?.should be_false
    end

    it "should leave the :ids_only option set and the results populated if it was set before" do
      stored_scope = Alpha.by_name('foo').ids_only
      stored_scope.search_count
      stored_scope.options[:ids_only].should be_true
      stored_scope.populated?.should be_true
    end
  end

end
