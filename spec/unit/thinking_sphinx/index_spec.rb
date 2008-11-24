require 'spec/spec_helper'

describe ThinkingSphinx::Index do
  describe "to_sql method" do
    it "should include explicit groupings if requested" do
      @index = ThinkingSphinx::Index.new(Person)
      
      @index.groupings << "custom_sql"
      @index.to_sql.should match(/GROUP BY.+custom_sql/)
    end
  end
  
  describe "to_sql_query_range method" do
    before :each do
      @index = ThinkingSphinx::Index.new(Person)
    end
    
    it "should add COALESCE around MIN and MAX calls if using PostgreSQL" do
      @index.stub_method(:adapter => :postgres)
      
      @index.to_sql_query_range.should match(/COALESCE\(MIN.+COALESCE\(MAX/)
    end
    
    it "shouldn't add COALESCE if using MySQL" do
      @index.to_sql_query_range.should_not match(/COALESCE/)
    end
  end
  
  describe "prefix_fields method" do
    before :each do
      @index = ThinkingSphinx::Index.new(Person)
      
      @field_a = ThinkingSphinx::Field.stub_instance(:prefixes => true)
      @field_b = ThinkingSphinx::Field.stub_instance(:prefixes => false)
      @field_c = ThinkingSphinx::Field.stub_instance(:prefixes => true)
      
      @index.fields = [@field_a, @field_b, @field_c]
    end
    
    it "should return fields that are flagged as prefixed" do
      @index.prefix_fields.should include(@field_a)
      @index.prefix_fields.should include(@field_c)
    end
    
    it "should not return fields that aren't flagged as prefixed" do
      @index.prefix_fields.should_not include(@field_b)
    end
  end
  
  describe "infix_fields method" do
    before :each do
      @index = ThinkingSphinx::Index.new(Person)
      
      @field_a = ThinkingSphinx::Field.stub_instance(:infixes => true)
      @field_b = ThinkingSphinx::Field.stub_instance(:infixes => false)
      @field_c = ThinkingSphinx::Field.stub_instance(:infixes => true)
      
      @index.fields = [@field_a, @field_b, @field_c]
    end
    
    it "should return fields that are flagged as infixed" do
      @index.infix_fields.should include(@field_a)
      @index.infix_fields.should include(@field_c)
    end
    
    it "should not return fields that aren't flagged as infixed" do
      @index.infix_fields.should_not include(@field_b)
    end
  end
  
  describe "empty? method" do
    before :each do
      @index = ThinkingSphinx::Index.new(Contact)
      config = ThinkingSphinx::Configuration.instance
      
      `mkdir -p #{config.searchd_file_path}`
      @file_path = "#{config.searchd_file_path}/#{@index.name}_core.spa"
    end
    
    after :each do
      FileUtils.rm(@file_path, :force => true)
    end
    
    it "should return true if the core index files are empty" do
      `touch #{@file_path}`
      @index.should be_empty
    end
    
    it "should return true if the core index files don't exist" do
      @index.should be_empty
    end
    
    it "should return false if the core index files aren't empty" do
      `echo 'a' > #{@file_path}`
      @index.should_not be_empty
    end
    
    it "should check the delta files if specified" do
      delta_path = @file_path.gsub(/_core.spa$/, '_delta.spa')
      
      @index.should be_empty(:delta)
      `echo 'a' > #{delta_path}`
      @index.should_not be_empty(:delta)
      
      FileUtils.rm(delta_path)
    end
  end
  
  describe "initialize_from_builder method" do
    it "should copy groupings across from the builder to the index" do
      @index = ThinkingSphinx::Index.new(Person) do
        group_by "custom_grouping"
      end
      @index.groupings.should include("custom_grouping")
    end
  end
end