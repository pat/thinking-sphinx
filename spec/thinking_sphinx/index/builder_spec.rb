require 'spec_helper'

describe ThinkingSphinx::Index::Builder do
  describe ".generate without source scope" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name, last_name
        has birthday
        has id, :as => :internal_id
        
        set_property :sql_range_step => 1000
        
        where "birthday <= NOW()"
        group_by "first_name"
      end
      
      @source = @index.sources.first
    end
    
    it "should return an index" do
      @index.should be_a_kind_of(ThinkingSphinx::Index)
    end
    
    it "should have one source for the index" do
      @index.sources.length.should == 1
    end
    
    it "should have two fields" do
      @source.fields.length.should == 2
      @source.fields[0].unique_name.should == :first_name
      @source.fields[1].unique_name.should == :last_name
    end
    
    it "should have two attributes alongside the three internal ones" do
      @source.attributes.length.should == 5
      @source.attributes[3].unique_name.should == :birthday
      @source.attributes[4].unique_name.should == :internal_id
    end
    
    it "should have one condition" do
      @source.conditions.length.should == 1
      @source.conditions.first.should == "birthday <= NOW()"
    end
    
    it "should have one grouping" do
      @source.groupings.length.should == 1
      @source.groupings.first.should == "first_name"
    end
    
    it "should have one option" do
      @source.options.length.should == 1
      @source.options[:sql_range_step].should == 1000
    end
  end
  
  describe 'aliased field' do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name, :as => 'name'
      end
      
      @source = @index.sources.first
    end
    
    it "should store the alias as a symbol for consistency" do
      @source.fields.last.unique_name.should == :name
    end
  end
  
  describe 'aliased attribute' do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name
        has :id, :as => 'real_id'
      end
      
      @source = @index.sources.first
    end
    
    it "should store the alias as a symbol for consistency" do
      @source.attributes.last.unique_name.should == :real_id
    end
  end
  
  describe "sortable field" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name, :sortable => true
      end
      
      @source = @index.sources.first
    end
    
    it "should have one field" do
      @source.fields.length.should == 1
    end
    
    it "should have one attribute alongside the three internal ones" do
      @source.attributes.length.should == 4
    end
    
    it "should set the attribute name to have the _sort suffix" do
      @source.attributes.last.unique_name.should == :first_name_sort
    end
    
    it "should set the attribute column to be the same as the field" do
      @source.attributes.last.columns.length.should == 1
      @source.attributes.last.columns.first.__name.should == :first_name
    end
  end
  
  describe '#join' do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name
        
        join contacts
      end
      
      @source = @index.sources.first
    end
    
    it "should include the explicit join" do
      @source.joins.length.should == 1
    end
  end
  
  describe "faceted field" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name, :facet => true
      end
      
      @source = @index.sources.first
    end
    
    after :each do
      Person.sphinx_facets.delete_at(-1)
    end
    
    it "should have one field" do
      @source.fields.length.should == 1
    end
    
    it "should have one attribute alongside the three internal ones" do
      @source.attributes.length.should == 4
    end
    
    it "should set the attribute name to have the _facet suffix" do
      @source.attributes.last.unique_name.should == :first_name_facet
    end
    
    it "should set the attribute type to integer" do
      @source.attributes.last.type.should == :integer
    end
    
    it "should set the attribute column to be the same as the field" do
      @source.attributes.last.columns.length.should == 1
      @source.attributes.last.columns.first.__name.should == :first_name
    end
  end
  
  describe "faceted integer attribute" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Alpha) do
        indexes :name
        has value, :facet => true
      end
      
      @source = @index.sources.first
    end
    
    after :each do
      Alpha.sphinx_facets.delete_at(-1)
    end
    
    it "should have just one attribute alongside the three internal ones" do
      @source.attributes.length.should == 4
    end
  end
  
  describe "faceted timestamp attribute" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name
        has birthday, :facet => true
      end
      
      @source = @index.sources.first
    end
    
    after :each do
      Person.sphinx_facets.delete_at(-1)
    end
    
    it "should have just one attribute alongside the three internal ones" do
      @source.attributes.length.should == 4
    end
  end
  
  describe "faceted boolean attribute" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Beta) do
        indexes :name
        has delta, :facet => true
      end
      
      @source = @index.sources.first
    end
    
    after :each do
      Beta.sphinx_facets.delete_at(-1)
    end
    
    it "should have just one attribute alongside the three internal ones" do
      @source.attributes.length.should == 4
    end
  end
  
  describe "faceted float attribute" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Alpha) do
        indexes :name
        has cost, :facet => true
      end
      
      @source = @index.sources.first
    end
    
    after :each do
      Alpha.sphinx_facets.delete_at(-1)
    end
    
    it "should have just one attribute alongside the three internal ones" do
      @source.attributes.length.should == 4
    end
  end
  
  describe "faceted string attribute" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name
        has last_name, :facet => true
      end
      
      @source = @index.sources.first
    end
    
    after :each do
      Person.sphinx_facets.delete_at(-1)
    end
    
    it "should have two attributes alongside the three internal ones" do
      @source.attributes.length.should == 5
    end
    
    it "should set the facet attribute name to have the _facet suffix" do
      @source.attributes.last.unique_name.should == :last_name_facet
    end
    
    it "should set the attribute type to integer" do
      @source.attributes.last.type.should == :integer
    end
    
    it "should set the attribute column to be the same as the field" do
      @source.attributes.last.columns.length.should == 1
      @source.attributes.last.columns.first.__name.should == :last_name
    end
  end
  
  describe 'faceted manual MVA' do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name
        has 'SQL STATEMENT', :type => :multi, :as => :sql, :facet => true
      end
      
      @source = @index.sources.first
    end
    
    after :each do
      Person.sphinx_facets.delete_at(-1)
    end
    
    it "should have two attributes alongside the three internal ones" do
      @source.attributes.length.should == 5
    end
    
    it "should set the facet attribute name to have the _facet suffix" do
      @source.attributes.last.unique_name.should == :sql_facet
    end
    
    it "should keep the original attribute's name set as requested" do
      @source.attributes[-2].unique_name.should == :sql
    end
    
    it "should set the attribute type to multi" do
      @source.attributes.last.type.should == :multi
    end
    
    it "should set the attribute column to be the same as the field" do
      @source.attributes.last.columns.length.should == 1
      @source.attributes.last.columns.first.__name.should == 'SQL STATEMENT'
    end
  end
  
  describe 'faceted MVA field' do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes tags(:name), :as => :tags, :facet => true
      end
      
      @source = @index.sources.first
    end
    
    after :each do
      Person.sphinx_facets.delete_at(-1)
    end
    
    it "should have one field" do
      @source.fields.length.should == 1
    end
    
    it "should have one attribute alongside the three internal ones" do
      @source.attributes.length.should == 4
    end
    
    it "should set the attribute name to have the _facet suffix" do
      @source.attributes.last.unique_name.should == :tags_facet
    end
    
    it "should set the attribute type to multi" do
      @source.attributes.last.type.should == :multi
    end
    
    it "should set the attribute column to be the same as the field" do
      @source.attributes.last.columns.length.should == 1
      @source.attributes.last.columns.first.__name.should == :name
    end
  end
  
  describe "no fields" do
    it "should raise an exception" do
      lambda {
        ThinkingSphinx::Index::Builder.generate(Person) do
          #
        end
      }.should raise_error
    end
  end
  
  describe "explicit source" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        define_source do
          indexes first_name, last_name
          has birthday
          has id, :as => :internal_id
        
          set_property :delta => true
        
          where "birthday <= NOW()"
          group_by "first_name"
        end
      end
      
      @source = @index.sources.first
    end
    
    it "should return an index" do
      @index.should be_a_kind_of(ThinkingSphinx::Index)
    end
    
    it "should have one source for the index" do
      @index.sources.length.should == 1
    end
    
    it "should have two fields" do
      @source.fields.length.should == 2
      @source.fields[0].unique_name.should == :first_name
      @source.fields[1].unique_name.should == :last_name
    end
    
    it "should have two attributes alongside the three internal ones" do
      @source.attributes.length.should == 5
      @source.attributes[3].unique_name.should == :birthday
      @source.attributes[4].unique_name.should == :internal_id
    end
  end
  
  describe "multiple sources" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        define_source do
          indexes first_name
          has birthday
        end
        
        define_source do
          indexes last_name
          has :id, :as => :internal_id
        end
      end
    end
    
    it "should have two sources" do
      @index.sources.length.should == 2
    end
    
    it "should have two fields" do
      @index.fields.length.should == 2
    end
    
    it "should have one field in each source" do
      @index.sources.each do |source|
        source.fields.length.should == 1
      end
    end
    
    it "should have two attributes alongside the six internal ones" do
      @index.attributes.length.should == 8
    end
    
    it "should have one attribute in each source alongside the three internal ones" do
      @index.sources.each do |source|
        source.attributes.length.should == 4
      end
    end
  end
  
  describe "index options" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name
        
        set_property :charset_type => "utf16"
        set_property :group_concat_max_len => 1024
      end
    end
    
    it "should store the index setting for the index" do
      @index.local_options[:charset_type].should == "utf16"
    end
    
    it "should store non-Sphinx settings for the index" do
      @index.local_options[:group_concat_max_len].should == 1024
    end
  end
  
  describe "delta options" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name
        
        set_property :delta => true
      end
    end
    
    it "should not keep the delta setting in source options" do
      @index.sources.first.options.should be_empty
    end
    
    it "should not keep the delta setting in index options" do
      @index.local_options.should be_empty
    end
    
    it "should set the index delta object set" do
      @index.delta_object.should be_a_kind_of(ThinkingSphinx::Deltas::DefaultDelta)
    end
  end
  
  context 'index options' do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name
        
        set_property :index_exact_words => true
      end
    end
    
    it "should track the index_exact_words option to the index" do
      @index.local_options[:index_exact_words].should be_true
    end
  end
  
  context 'with an explicit name' do
    it "should set the index's name using the provided value" do
      index = ThinkingSphinx::Index::Builder.generate(Person, 'custom') do
        indexes first_name
      end
      
      index.name.should == 'custom'
    end
  end
end