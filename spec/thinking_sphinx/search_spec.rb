require 'spec/spec_helper'
require 'will_paginate/collection'

describe ThinkingSphinx::Search do
  before :each do
    @config = ThinkingSphinx::Configuration.instance
    @client = Riddle::Client.new
    
    @config.stub!(:client => @client)
    @client.stub!(:query => {:matches => [], :total_found => 41, :total => 41})
  end
  
  it "not request results from the client if not accessing items" do
    @config.should_not_receive(:client)
    
    ThinkingSphinx::Search.new.class
  end
  
  it "should request results if access is required" do
    @config.should_receive(:client)
    
    ThinkingSphinx::Search.new.first
  end
  
  describe '#respond_to?' do
    it "should respond to Array methods" do
      ThinkingSphinx::Search.new.respond_to?(:each).should be_true
    end
    
    it "should respond to Search methods" do
      ThinkingSphinx::Search.new.respond_to?(:per_page).should be_true
    end
  end
  
  describe '#populated?' do
    before :each do
      @search = ThinkingSphinx::Search.new
    end
    
    it "should be false if the client request has not been made" do
      @search.populated?.should be_false
    end
    
    it "should be true once the client request has been made" do
      @search.first
      @search.populated?.should be_true
    end
  end
  
  describe '#results' do
    it "should populate search results before returning" do
      @search = ThinkingSphinx::Search.new
      @search.populated?.should be_false
      
      @search.results
      @search.populated?.should be_true
    end
  end
  
  describe '#method_missing' do
    before :each do
      Alpha.sphinx_scope(:by_name) { |name|
        {:conditions => {:name => name}}
      }
      Alpha.sphinx_scope(:ids_only) { {:ids_only => true} }
    end
    
    after :each do
      Alpha.remove_sphinx_scopes
    end
    
    it "should handle Array methods" do
      ThinkingSphinx::Search.new.private_methods.should be_an(Array)
    end
    
    it "should raise a NoMethodError exception if unknown method" do
      lambda {
        ThinkingSphinx::Search.new.foo
      }.should raise_error(NoMethodError)
    end
    
    it "should not request results from client if method does not exist" do
      @client.should_not_receive(:query)
      
      lambda {
        ThinkingSphinx::Search.new.foo
      }.should raise_error(NoMethodError)
    end
    
    it "should accept sphinx scopes" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      
      lambda {
        search.by_name('Pat')
      }.should_not raise_error(NoMethodError)
    end
    
    it "should return itself when using a sphinx scope" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_name('Pat').object_id.should == search.object_id
    end
    
    it "should keep the same search object when chaining multiple scopes" do
      search = ThinkingSphinx::Search.new(:classes => [Alpha])
      search.by_name('Pat').ids_only.object_id.should == search.object_id
    end
  end
  
  describe '.search' do
    it "return the output of ThinkingSphinx.search" do
      @results = [] # to confirm same object
      ThinkingSphinx.stub!(:search => @results)
      
      ThinkingSphinx::Search.search.object_id.should == @results.object_id
    end
  end
  
  describe '.search_for_ids' do
    it "return the output of ThinkingSphinx.search_for_ids" do
      @results = [] # to confirm same object
      ThinkingSphinx.stub!(:search_for_ids => @results)
      
      ThinkingSphinx::Search.search_for_ids.object_id.
        should == @results.object_id
    end
  end
  
  describe '.search_for_id' do
    it "return the output of ThinkingSphinx.search_for_ids" do
      @results = [] # to confirm same object
      ThinkingSphinx.stub!(:search_for_id => @results)
      
      ThinkingSphinx::Search.search_for_id.object_id.
        should == @results.object_id
    end
  end
  
  describe '.count' do
    it "return the output of ThinkingSphinx.search" do
      @results = [] # to confirm same object
      ThinkingSphinx.stub!(:count => @results)
      
      ThinkingSphinx::Search.count.object_id.should == @results.object_id
    end
  end
  
  describe '.facets' do
    it "return the output of ThinkingSphinx.facets" do
      @results = [] # to confirm same object
      ThinkingSphinx.stub!(:facets => @results)
      
      ThinkingSphinx::Search.facets.object_id.should == @results.object_id
    end
  end
  
  describe '#populate' do
    before :each do
      @alpha_a, @alpha_b  = Alpha.new,  Alpha.new
      @beta_a, @beta_b    = Beta.new,   Beta.new
      
      @alpha_a.stub! :id => 1, :read_attribute => 1
      @alpha_b.stub! :id => 2, :read_attribute => 2
      @beta_a.stub!  :id => 1, :read_attribute => 1
      @beta_b.stub!  :id => 2, :read_attribute => 2
      
      @client.stub! :query => {
        :matches => minimal_result_hashes(@alpha_a, @beta_b, @alpha_b, @beta_a)
      }
      Alpha.stub! :find => [@alpha_a, @alpha_b]
      Beta.stub!  :find => [@beta_a, @beta_b]
    end
    
    it "should issue only one select per model" do
      Alpha.should_receive(:find).once.and_return([@alpha_a, @alpha_b])
      Beta.should_receive(:find).once.and_return([@beta_a, @beta_b])
      
      ThinkingSphinx::Search.new.first
    end
    
    it "should mix the results from different models" do
      search = ThinkingSphinx::Search.new
      search[0].should be_a(Alpha)
      search[1].should be_a(Beta)
      search[2].should be_a(Alpha)
      search[3].should be_a(Beta)
    end
    
    it "should maintain the Xoopit ordering for results" do
      search = ThinkingSphinx::Search.new
      search[0].id.should == 1
      search[1].id.should == 2
      search[2].id.should == 2
      search[3].id.should == 1
    end
    
    it "should use the requested classes to generate the index argument" do
      @client.should_receive(:query) do |query, index, comment|
        index.should == 'alpha_core,beta_core,beta_delta'
      end
      
      ThinkingSphinx::Search.new(:classes => [Alpha, Beta]).first
    end
    
    describe 'query' do
      it "should concatenate arguments with spaces" do
        @client.should_receive(:query) do |query, index, comment|
          query.should == 'two words'
        end
        
        ThinkingSphinx::Search.new('two', 'words').first
      end
      
      it "should append conditions to the query" do
        @client.should_receive(:query) do |query, index, comment|
          query.should == 'general @focused specific'
        end
        
        ThinkingSphinx::Search.new('general', :conditions => {
          :focused => 'specific'
        }).first
      end
      
      it "append multiple conditions together" do
        @client.should_receive(:query) do |query, index, comment|
          query.should match(/general.+@foo word/)
          query.should match(/general.+@bar word/)
        end
        
        ThinkingSphinx::Search.new('general', :conditions => {
          :foo => 'word', :bar => 'word'
        }).first
      end
      
      it "should apply stars if requested, and handle full extended syntax" do
        input    = %{a b* c (d | e) 123 5&6 (f_f g) !h "i j" "k l"~10 "m n"/3 @o p -(q|r)}
        expected = %{*a* b* *c* (*d* | *e*) *123* *5*&*6* (*f_f* *g*) !*h* "i j" "k l"~10 "m n"/3 @o *p* -(*q*|*r*)}
        
        @client.should_receive(:query) do |query, index, comment|
          query.should == expected
        end
        
        ThinkingSphinx::Search.new(input, :star => true).first
      end

      it "should default to /\w+/ as token for auto-starring" do
        @client.should_receive(:query) do |query, index, comment|
          query.should == '*foo*@*bar*.*com*'
        end
        
        ThinkingSphinx::Search.new('foo@bar.com', :star => true).first
      end

      it "should honour custom star tokens" do
        @client.should_receive(:query) do |query, index, comment|
          query.should == '*foo@bar.com* -*foo-bar*'
        end
        
        ThinkingSphinx::Search.new(
          'foo@bar.com -foo-bar', :star => /[\w@.-]+/u
        ).first
      end
    end
    
    describe 'comment' do
      it "should add comment if explicitly provided" do
        @client.should_receive(:query) do |query, index, comment|
          comment.should == 'custom log'
        end
        
        ThinkingSphinx::Search.new(:comment => 'custom log').first
      end
      
      it "should default to a blank comment" do
        @client.should_receive(:query) do |query, index, comment|
          comment.should == ''
        end
        
        ThinkingSphinx::Search.new.first
      end
    end
    
    describe 'match mode' do
      it "should default to :all" do
        ThinkingSphinx::Search.new.first
        
        @client.match_mode.should == :all
      end
      
      it "should default to :extended if conditions are supplied" do
        ThinkingSphinx::Search.new('general', :conditions => {
          :foo => 'word', :bar => 'word'
        }).first
        
        @client.match_mode.should == :extended
      end
      
      it "should use explicit match modes" do
        ThinkingSphinx::Search.new('general', :conditions => {
          :foo => 'word', :bar => 'word'
        }, :match_mode => :extended2).first
        
        @client.match_mode.should == :extended2
      end
    end

    describe 'sphinx_select' do
      it "should default to *" do
        ThinkingSphinx::Search.new.first
        
        @client.select.should == "*"
      end
      
      it "should get set on the client if specified" do
        ThinkingSphinx::Search.new('general',
          :sphinx_select => "*, foo as bar"
        ).first
        
        @client.select.should == "*, foo as bar"
      end

    end
    
    describe 'pagination' do
      it "should set the limit using per_page" do
        ThinkingSphinx::Search.new(:per_page => 30).first
        @client.limit.should == 30
      end
      
      it "should set the offset if pagination is requested" do
        ThinkingSphinx::Search.new(:page => 3).first
        @client.offset.should == 40
      end
      
      it "should set the offset by the per_page value" do
        ThinkingSphinx::Search.new(:page => 3, :per_page => 30).first
        @client.offset.should == 60
      end
    end
    
    describe 'filters' do
      it "should filter out deleted values by default" do
        ThinkingSphinx::Search.new.first
        
        filter = @client.filters.last
        filter.values.should == [0]
        filter.attribute.should == 'sphinx_deleted'
        filter.exclude?.should be_false
      end
      
      it "should add class filters for explicit classes" do
        ThinkingSphinx::Search.new(:classes => [Alpha, Beta]).first
        
        filter = @client.filters.last
        filter.values.should == [Alpha.to_crc32, Beta.to_crc32]
        filter.attribute.should == 'class_crc'
        filter.exclude?.should be_false
      end
      
      it "should add class filters for subclasses of requested classes" do
        ThinkingSphinx::Search.new(:classes => [Person]).first
        
        filter = @client.filters.last
        filter.values.should == [
          Parent.to_crc32, Admin::Person.to_crc32,
          Child.to_crc32, Person.to_crc32
        ]
        filter.attribute.should == 'class_crc'
        filter.exclude?.should be_false
      end
      
      it "should append inclusive filters of integers" do
        ThinkingSphinx::Search.new(:with => {:int => 1}).first
        
        filter = @client.filters.last
        filter.values.should    == [1]
        filter.attribute.should == 'int'
        filter.exclude?.should be_false
      end
      
      it "should append inclusive filters of floats" do
        ThinkingSphinx::Search.new(:with => {:float => 1.5}).first
        
        filter = @client.filters.last
        filter.values.should    == [1.5]
        filter.attribute.should == 'float'
        filter.exclude?.should be_false
      end
      
      it "should append inclusive filters of booleans" do
        ThinkingSphinx::Search.new(:with => {:boolean => true}).first
        
        filter = @client.filters.last
        filter.values.should    == [true]
        filter.attribute.should == 'boolean'
        filter.exclude?.should be_false
      end
      
      it "should append inclusive filters of arrays" do
        ThinkingSphinx::Search.new(:with => {:ints => [1, 2, 3]}).first
        
        filter = @client.filters.last
        filter.values.should    == [1, 2, 3]
        filter.attribute.should == 'ints'
        filter.exclude?.should be_false
      end
      
      it "should treat nils in arrays as 0" do
        ThinkingSphinx::Search.new(:with => {:ints => [nil, 1, 2, 3]}).first
        
        filter = @client.filters.last
        filter.values.should    == [0, 1, 2, 3]
      end
      
      it "should append inclusive filters of time ranges" do
        first, last = 1.week.ago, Time.now
        ThinkingSphinx::Search.new(:with => {
          :time => first..last
        }).first
        
        filter = @client.filters.last
        filter.values.should    == (first.to_i..last.to_i)
        filter.attribute.should == 'time'
        filter.exclude?.should be_false
      end
      
      it "should append exclusive filters of integers" do
        ThinkingSphinx::Search.new(:without => {:int => 1}).first
        
        filter = @client.filters.last
        filter.values.should    == [1]
        filter.attribute.should == 'int'
        filter.exclude?.should be_true
      end
      
      it "should append exclusive filters of floats" do
        ThinkingSphinx::Search.new(:without => {:float => 1.5}).first
        
        filter = @client.filters.last
        filter.values.should    == [1.5]
        filter.attribute.should == 'float'
        filter.exclude?.should be_true
      end
      
      it "should append exclusive filters of booleans" do
        ThinkingSphinx::Search.new(:without => {:boolean => true}).first
        
        filter = @client.filters.last
        filter.values.should    == [true]
        filter.attribute.should == 'boolean'
        filter.exclude?.should be_true
      end
      
      it "should append exclusive filters of arrays" do
        ThinkingSphinx::Search.new(:without => {:ints => [1, 2, 3]}).first
        
        filter = @client.filters.last
        filter.values.should    == [1, 2, 3]
        filter.attribute.should == 'ints'
        filter.exclude?.should be_true
      end
      
      it "should append exclusive filters of time ranges" do
        first, last = 1.week.ago, Time.now
        ThinkingSphinx::Search.new(:without => {
          :time => first..last
        }).first
        
        filter = @client.filters.last
        filter.values.should    == (first.to_i..last.to_i)
        filter.attribute.should == 'time'
        filter.exclude?.should be_true
      end
      
      it "should add separate filters for each item in a with_all value" do
        ThinkingSphinx::Search.new(:with_all => {:ints => [1, 2, 3]}).first
        
        filters = @client.filters[-3, 3]
        filters.each do |filter|
          filter.attribute.should == 'ints'
          filter.exclude?.should be_false
        end
        
        filters[0].values.should == [1]
        filters[1].values.should == [2]
        filters[2].values.should == [3]
      end
      
      it "should filter out specific ids using :without_ids" do
        ThinkingSphinx::Search.new(:without_ids => [4, 5, 6]).first
        
        filter = @client.filters.last
        filter.values.should    == [4, 5, 6]
        filter.attribute.should == 'sphinx_internal_id'
        filter.exclude?.should be_true
      end
      
      describe 'in :conditions' do
        it "should add as filters for known attributes in :conditions option" do
          ThinkingSphinx::Search.new('general',
            :conditions => {:word => 'specific', :lat => 1.5},
            :classes    => [Alpha]
          ).first
          
          filter = @client.filters.last
          filter.values.should == [1.5]
          filter.attribute.should == 'lat'
          filter.exclude?.should be_false        
        end
        
        it "should not add the filter to the query string" do
          @client.should_receive(:query) do |query, index, comment|
            query.should == 'general @word specific'
          end
          
          ThinkingSphinx::Search.new('general',
            :conditions => {:word => 'specific', :lat => 1.5},
            :classes    => [Alpha]
          ).first
        end
      end
    end
    
    describe 'sort mode' do
      it "should use :relevance as a default" do
        ThinkingSphinx::Search.new.first
        @client.sort_mode.should == :relevance
      end

      it "should use :attr_asc if a symbol is supplied to :order" do
        ThinkingSphinx::Search.new(:order => :created_at).first
        @client.sort_mode.should == :attr_asc
      end

      it "should use :attr_desc if :desc is the mode" do
        ThinkingSphinx::Search.new(
          :order => :created_at, :sort_mode => :desc
        ).first
        @client.sort_mode.should == :attr_desc
      end

      it "should use :extended if a string is supplied to :order" do
        ThinkingSphinx::Search.new(:order => "created_at ASC").first
        @client.sort_mode.should == :extended
      end

      it "should use :expr if explicitly requested" do
        ThinkingSphinx::Search.new(
          :order => "created_at ASC", :sort_mode => :expr
        ).first
        @client.sort_mode.should == :expr
      end

      it "should use :attr_desc if explicitly requested" do
        ThinkingSphinx::Search.new(
          :order => "created_at", :sort_mode => :desc
        ).first
        @client.sort_mode.should == :attr_desc
      end
    end
    
    describe 'sort by' do
      it "should presume order symbols are attributes" do
        ThinkingSphinx::Search.new(:order => :created_at).first
        @client.sort_by.should == 'created_at'
      end
      
      it "replace field names with their sortable attributes" do
        ThinkingSphinx::Search.new(:order => :name, :classes => [Alpha]).first
        @client.sort_by.should == 'name_sort'
      end
      
      it "should replace field names in strings" do
        ThinkingSphinx::Search.new(
          :order => "created_at ASC, name DESC", :classes => [Alpha]
        ).first
        @client.sort_by.should == 'created_at ASC, name_sort DESC'
      end
    end
    
    describe 'max matches' do
      it "should use the global setting by default" do
        ThinkingSphinx::Search.new.first
        @client.max_matches.should == 1000
      end
      
      it "should use explicit setting" do
        ThinkingSphinx::Search.new(:max_matches => 2000).first
        @client.max_matches.should == 2000
      end
    end
    
    describe 'field weights' do
      it "should set field weights as provided" do
        ThinkingSphinx::Search.new(
          :field_weights => {'foo' => 10, 'bar' => 5}
        ).first
        
        @client.field_weights.should == {
          'foo' => 10, 'bar' => 5
        }
      end
      
      it "should use field weights set in the index" do
        ThinkingSphinx::Search.new(:classes => [Alpha]).first
        
        @client.field_weights.should == {'name' => 10}
      end
    end
    
    describe 'index weights' do
      it "should send index weights through to the client" do
        ThinkingSphinx::Search.new(:index_weights => {'foo' => 100}).first
        @client.index_weights.should == {'foo' => 100}
      end
      
      it "should convert classes to their core and delta index names" do
        ThinkingSphinx::Search.new(:index_weights => {Alpha => 100}).first
        @client.index_weights.should == {
          'alpha_core'  => 100,
          'alpha_delta' => 100
        }
      end
    end
    
    describe 'grouping' do
      it "should convert group into group_by and group_function" do
        ThinkingSphinx::Search.new(:group => :edition).first
        
        @client.group_function.should == :attr
        @client.group_by.should == "edition"
      end
      
      it "should pass on explicit grouping arguments" do
        ThinkingSphinx::Search.new(
          :group_by       => 'created_at',
          :group_function => :attr,
          :group_clause   => 'clause',
          :group_distinct => 'distinct'
        ).first
        
        @client.group_by.should       == 'created_at'
        @client.group_function.should == :attr
        @client.group_clause.should   == 'clause'
        @client.group_distinct.should == 'distinct'
      end
    end
    
    describe 'anchor' do
      it "should detect lat and lng attributes on the given model" do
        ThinkingSphinx::Search.new(
          :geo     => [1.0, -1.0],
          :classes => [Alpha]
        ).first
        
        @client.anchor[:latitude_attribute].should == 'lat'
        @client.anchor[:longitude_attribute].should == 'lng'
      end
      
      it "should detect lat and lon attributes on the given model" do
        ThinkingSphinx::Search.new(
          :geo     => [1.0, -1.0],
          :classes => [Beta]
        ).first
        
        @client.anchor[:latitude_attribute].should == 'lat'
        @client.anchor[:longitude_attribute].should == 'lon'
      end
      
      it "should detect latitude and longitude attributes on the given model" do
        ThinkingSphinx::Search.new(
          :geo     => [1.0, -1.0],
          :classes => [Person]
        ).first
        
        @client.anchor[:latitude_attribute].should == 'latitude'
        @client.anchor[:longitude_attribute].should == 'longitude'
      end
      
      it "should accept manually defined latitude and longitude attributes" do
        ThinkingSphinx::Search.new(
          :geo            => [1.0, -1.0],
          :classes        => [Alpha],
          :latitude_attr  => :updown,
          :longitude_attr => :leftright
        ).first
        
        @client.anchor[:latitude_attribute].should == 'updown'
        @client.anchor[:longitude_attribute].should == 'leftright'
      end
      
      it "should accept manually defined latitude and longitude attributes in the given model" do
        ThinkingSphinx::Search.new(
          :geo     => [1.0, -1.0],
          :classes => [Friendship]
        ).first
        
        @client.anchor[:latitude_attribute].should == 'person_id'
        @client.anchor[:longitude_attribute].should == 'person_id'
      end
      
      it "should accept geo array for geo-position values" do
        ThinkingSphinx::Search.new(
          :geo     => [1.0, -1.0],
          :classes => [Alpha]
        ).first
        
        @client.anchor[:latitude].should == 1.0
        @client.anchor[:longitude].should == -1.0
      end
      
      it "should accept lat and lng options for geo-position values" do
        ThinkingSphinx::Search.new(
          :lat     => 1.0,
          :lng     => -1.0,
          :classes => [Alpha]
        ).first
        
        @client.anchor[:latitude].should == 1.0
        @client.anchor[:longitude].should == -1.0
      end
    end
    
    describe 'sql ordering' do
      before :each do
        @client.stub! :query => {
          :matches => minimal_result_hashes(@alpha_b, @alpha_a)
        }
        Alpha.stub! :find => [@alpha_a, @alpha_b]
      end
      
      it "shouldn't re-sort SQL results based on Sphinx information" do
        search = ThinkingSphinx::Search.new(
          :classes    => [Alpha],
          :sql_order  => 'id'
        )
        search.first.should == @alpha_a
        search.last.should  == @alpha_b
      end
      
      it "should use the option for the ActiveRecord::Base#find calls" do
        Alpha.should_receive(:find) do |mode, options|
          options[:order].should == 'id'
        end
        
        ThinkingSphinx::Search.new(
          :classes    => [Alpha],
          :sql_order  => 'id'
        ).first
      end
    end
    
    context 'result objects' do
      describe '#excerpts' do
        before :each do
          @search = ThinkingSphinx::Search.new
        end
      
        it "should add excerpts method if objects don't already have one" do
          @search.first.should respond_to(:excerpts)
        end
      
        it "should return an instance of ThinkingSphinx::Excerpter" do
          @search.first.excerpts.should be_a(ThinkingSphinx::Excerpter)
        end
      
        it "should not add excerpts method if objects already have one" do
          @search.last.excerpts.should_not be_a(ThinkingSphinx::Excerpter)
        end
      
        it "should set up the excerpter with the instances and search" do
          ThinkingSphinx::Excerpter.should_receive(:new).with(@search, @alpha_a)
          ThinkingSphinx::Excerpter.should_receive(:new).with(@search, @alpha_b)
        
          @search.first
        end
      end
    
      describe '#sphinx_attributes' do
        before :each do
          @search = ThinkingSphinx::Search.new
        end
        
        it "should add sphinx_attributes method if objects don't already have one" do
          @search.last.should respond_to(:sphinx_attributes)
        end
        
        it "should return a hash" do
          @search.last.sphinx_attributes.should be_a(Hash)
        end
        
        it "should not add sphinx_attributes if objects have a method of that name already" do
          @search.first.sphinx_attributes.should_not be_a(Hash)
        end
        
        it "should pair sphinx_attributes with the correct hash" do
          hash = @search.last.sphinx_attributes
          hash['sphinx_internal_id'].should == @search.last.id
          hash['class_crc'].should == @search.last.class.to_crc32
        end
      end
    end
  end
  
  describe '#current_page' do
    it "should return 1 by default" do
      ThinkingSphinx::Search.new.current_page.should == 1
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
  
  describe '#per_page' do
    it "should return 20 by default" do
      ThinkingSphinx::Search.new.per_page.should == 20
    end
    
    it "should allow for custom values" do
      ThinkingSphinx::Search.new(:per_page => 30).per_page.should == 30
    end
    
    it "should prioritise :limit over :per_page if given" do
      ThinkingSphinx::Search.new(
        :per_page => 30, :limit => 40
      ).per_page.should == 40
    end
    
    it "should allow for string arguments" do
      ThinkingSphinx::Search.new(:per_page => '10').per_page.should == 10
    end
  end
  
  describe '#total_pages' do
    it "should calculate the total pages depending on per_page and total_entries" do
      ThinkingSphinx::Search.new.total_pages.should == 3
    end
    
    it "should allow for custom per_page values" do
      ThinkingSphinx::Search.new(:per_page => 30).total_pages.should == 2
    end
    
    it "should not overstep the max_matches implied limit" do
      @client.stub!(:query => {
        :matches => [], :total_found => 41, :total => 40
      })
      
      ThinkingSphinx::Search.new.total_pages.should == 2
    end
    
    it "should return 0 if there is no index and therefore no results" do
      @client.stub!(:query => {
        :matches => [], :total_found => nil, :total => nil
      })
      
      ThinkingSphinx::Search.new.total_pages.should == 0
    end
  end
  
  describe '#next_page' do
    it "should return one more than the current page" do
      ThinkingSphinx::Search.new.next_page.should == 2
    end
    
    it "should return nil if on the last page" do
      ThinkingSphinx::Search.new(:page => 3).next_page.should be_nil
    end
  end
  
  describe '#previous_page' do
    it "should return one less than the current page" do
      ThinkingSphinx::Search.new(:page => 2).previous_page.should == 1
    end
    
    it "should return nil if on the first page" do
      ThinkingSphinx::Search.new.previous_page.should be_nil
    end
  end
  
  describe '#total_entries' do
    it "should return the total number of results, not just the amount on the page" do
      ThinkingSphinx::Search.new.total_entries.should == 41
    end
    
    it "should return 0 if there is no index and therefore no results" do
      @client.stub!(:query => {
        :matches => [], :total_found => nil
      })
      
      ThinkingSphinx::Search.new.total_entries.should == 0
    end
  end
  
  describe '#offset' do
    it "should default to 0" do
      ThinkingSphinx::Search.new.offset.should == 0
    end
    
    it "should increase by the per_page value for each page in" do
      ThinkingSphinx::Search.new(:per_page => 25, :page => 2).offset.should == 25
    end
  end
  
  describe '#indexes' do
    it "should default to '*'" do
      ThinkingSphinx::Search.new.indexes.should == '*'
    end
    
    it "should use given class to determine index name" do
      ThinkingSphinx::Search.new(:classes => [Alpha]).indexes.
        should == 'alpha_core'
    end
    
    it "should add both core and delta indexes for given classes" do
      ThinkingSphinx::Search.new(:classes => [Alpha, Beta]).indexes.
        should == 'alpha_core,beta_core,beta_delta'
    end
    
    it "should respect the :index option" do
      ThinkingSphinx::Search.new(:classes => [Alpha], :index => '*').indexes.
        should == '*'
    end
  end
  
  describe '.each_with_groupby_and_count' do
    before :each do
      @alpha = Alpha.new
      @alpha.stub!(:id => 1, :read_attribute => 1)
      
      @client.stub! :query => {
        :matches => [{
          :attributes => {
            'sphinx_internal_id' => @alpha.id,
            'class_crc'          => Alpha.to_crc32,
            '@groupby'           => 101,
            '@count'             => 5
          }
        }]
      }
      Alpha.stub!(:find => [@alpha])
    end
    
    it "should yield the match, group and count" do
      search = ThinkingSphinx::Search.new
      search.each_with_groupby_and_count do |obj, group, count|
        obj.should    == @alpha
        group.should  == 101
        count.should  == 5
      end
    end
    
    it "should be aliased to each_with_group_and_count" do
      search = ThinkingSphinx::Search.new
      search.each_with_group_and_count do |obj, group, count|
        obj.should    == @alpha
        group.should  == 101
        count.should  == 5
      end
    end
  end
  
  describe '.each_with_weighting' do
    before :each do
      @alpha = Alpha.new
      @alpha.stub!(:id => 1, :read_attribute => 1)
      
      @client.stub! :query => {
        :matches => [{
          :attributes => {
            'sphinx_internal_id' => @alpha.id,
            'class_crc'          => Alpha.to_crc32
          }, :weight => 12
        }]
      }
      Alpha.stub!(:find => [@alpha])
    end
    
    it "should yield the match and weight" do
      search = ThinkingSphinx::Search.new
      search.each_with_weighting do |obj, weight|
        obj.should    == @alpha
        weight.should == 12
      end
    end
  end
  
  describe '.each_with_*' do
    before :each do
      @alpha = Alpha.new
      @alpha.stub!(:id => 1, :read_attribute => 1)
      
      @client.stub! :query => {
        :matches => [{
          :attributes => {
            'sphinx_internal_id' => @alpha.id,
            'class_crc'          => Alpha.to_crc32,
            '@geodist'           => 101,
            '@groupby'           => 102,
            '@count'             => 103
          }, :weight => 12
        }]
      }
      Alpha.stub!(:find => [@alpha])
      
      @search = ThinkingSphinx::Search.new
    end
    
    it "should yield geodist if requested" do
      @search.each_with_geodist do |obj, distance|
        obj.should      == @alpha
        distance.should == 101
      end
    end
    
    it "should yield count if requested" do
      @search.each_with_count do |obj, count|
        obj.should    == @alpha
        count.should  == 103
      end
    end
    
    it "should yield groupby if requested" do
      @search.each_with_groupby do |obj, group|
        obj.should    == @alpha
        group.should  == 102
      end
    end
    
    it "should still use the array's each_with_index" do
      @search.each_with_index do |obj, index|
        obj.should   == @alpha
        index.should == 0
      end
    end
  end
  
  describe '#excerpt_for' do
    before :each do
      @client.stub!(:excerpts => ['excerpted string'])
      @client.stub!(:query => {
        :matches => [],
        :words => {'one' => {}, 'two' => {}}
      })
      @search = ThinkingSphinx::Search.new(:classes => [Alpha])
    end
    
    it "should return the Sphinx excerpt value" do
      @search.excerpt_for('string').should == 'excerpted string'
    end
    
    it "should use the given model's core index" do
      @client.should_receive(:excerpts) do |options|
        options[:index].should == 'alpha_core'
      end
      
      @search.excerpt_for('string')
    end
    
    it "should optionally take a second argument to allow for multi-model searches" do
      @client.should_receive(:excerpts) do |options|
        options[:index].should == 'beta_core'
      end
      
      @search.excerpt_for('string', Beta)
    end
    
    it "should join the words together" do
      @client.should_receive(:excerpts) do |options|
        options[:words].should == @search.results[:words].keys.join(' ')
      end
      
      @search.excerpt_for('string', Beta)
    end
    
    it "should use the correct index in STI situations" do
      @client.should_receive(:excerpts) do |options|
        options[:index].should == 'person_core'
      end
      
      @search.excerpt_for('string', Parent)
    end
  end
  
  describe '#search' do
    before :each do
      @search = ThinkingSphinx::Search.new('word',
        :conditions => {:field  => 'field'},
        :with       => {:int    => 5}
      )
    end
    
    it "should return itself" do
      @search.search.object_id.should == @search.object_id
    end
    
    it "should merge in arguments" do
      @client.should_receive(:query) do |query, index, comments|
        query.should == 'word more @field field'
      end
      
      @search.search('more').first
    end
    
    it "should merge conditions" do
      @client.should_receive(:query) do |query, index, comments|
        query.should match(/@name plato/)
        query.should match(/@field field/)
      end
      
      @search.search(:conditions => {:name => 'plato'}).first
    end
    
    it "should merge filters" do
      @search.search(:with => {:float => 1.5}).first
      
      @client.filters.detect { |filter|
        filter.attribute == 'float'
      }.should_not be_nil
      @client.filters.detect { |filter|
        filter.attribute == 'int'
      }.should_not be_nil
    end
  end
end

describe ThinkingSphinx::Search, "playing nice with Search model" do
  it "should not conflict with models called Search" do
    lambda { Search.find(:all) }.should_not raise_error
  end
end
