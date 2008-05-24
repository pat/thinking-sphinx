require 'spec/spec_helper'

describe ThinkingSphinx::Field do
  describe "to_select_sql method" do
    before :each do
      @index = Person.indexes.first
      @index.link!
    end
    
    it "should concat with spaces if there are multiple columns" do
      @index.fields.first.to_select_sql.should match(/CONCAT_WS\(' ', /)
    end
    
    it "should concat with spaces if a column has more than one association" do
      @index.fields[1].to_select_sql.should match(/CONCAT_WS\(' ', /)
    end
    
    it "should group if any association for any column is a has_many or has_and_belongs_to_many" do
      @index.fields[2].to_select_sql.should match(/GROUP_CONCAT/)
    end
  end
  
  describe "to_group_sql method" do
    before :each do
      @field = ThinkingSphinx::Field.new([])
      @field.stub_methods(:is_many? => false)
      
      ThinkingSphinx.stub_method(:use_group_by_shortcut? => false)
    end
    
    it "should return nil if is_many?" do
      @field.stub_method(:is_many? => true)
      
      @field.to_group_sql.should be_nil
    end
    
    it "should return nil if group_by shortcut is allowed" do
      ThinkingSphinx.stub_method(:use_group_by_shortcut? => true)
      
      @field.to_group_sql.should be_nil
    end
    
    it "should return an array if neither is_many? or shortcut allowed" do
      @field.to_group_sql.should be_a_kind_of(Array)
    end
    
    after :each do
      ThinkingSphinx.unstub_method(:use_group_by_shortcut?)
    end
  end
  
  describe "prefixes method" do
    it "should default to false" do
      @field = ThinkingSphinx::Field.new([])
      @field.prefixes.should be_false
    end
    
    it "should be true if the corresponding option is set" do
      @field = ThinkingSphinx::Field.new([], :prefixes => true)
      @field.prefixes.should be_true
    end
  end
  
  describe "infixes method" do
    it "should default to false" do
      @field = ThinkingSphinx::Field.new([])
      @field.infixes.should be_false
    end
    
    it "should be true if the corresponding option is set" do
      @field = ThinkingSphinx::Field.new([], :infixes => true)
      @field.infixes.should be_true
    end
  end
end