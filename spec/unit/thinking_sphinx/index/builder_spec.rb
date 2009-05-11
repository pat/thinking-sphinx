require 'spec/spec_helper'

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
    
    it "should have two attributes" do
      @source.attributes.length.should == 2
      @source.attributes[0].unique_name.should == :birthday
      @source.attributes[1].unique_name.should == :internal_id
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
    
    it "should have one attribute" do
      @source.attributes.length.should == 1
    end
    
    it "should set the attribute name to have the _sort suffix" do
      @source.attributes.first.unique_name.should == :first_name_sort
    end
    
    it "should set the attribute column to be the same as the field" do
      @source.attributes.first.columns.length.should == 1
      @source.attributes.first.columns.first.__name.should == :first_name
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
    
    it "should have one attribute" do
      @source.attributes.length.should == 1
    end
    
    it "should set the attribute name to have the _facet suffix" do
      @source.attributes.first.unique_name.should == :first_name_facet
    end
    
    it "should set the attribute column to be the same as the field" do
      @source.attributes.first.columns.length.should == 1
      @source.attributes.first.columns.first.__name.should == :first_name
    end
  end
  
  describe "faceted attribute" do
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
    
    it "should have two attributes" do
      @source.attributes.length.should == 2
    end
    
    it "should set the facet attribute name to have the _facet suffix" do
      @source.attributes.last.unique_name.should == :birthday_facet
    end
    
    it "should set the attribute column to be the same as the field" do
      @source.attributes.last.columns.length.should == 1
      @source.attributes.last.columns.first.__name.should == :birthday
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
    
    it "should have two attributes" do
      @source.attributes.length.should == 2
      @source.attributes[0].unique_name.should == :birthday
      @source.attributes[1].unique_name.should == :internal_id
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
    
    it "should have two attributes" do
      @index.attributes.length.should == 2
    end
    
    it "should have one attribute in each source" do
      @index.sources.each do |source|
        source.attributes.length.should == 1
      end
    end
  end
  
  describe "index options" do
    before :each do
      @index = ThinkingSphinx::Index::Builder.generate(Person) do
        indexes first_name
        
        set_property :charset_type => "utf16"
      end
    end
    
    it "should store the setting for the index" do
      @index.local_options.length.should == 1
      @index.local_options[:charset_type].should == "utf16"
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
end