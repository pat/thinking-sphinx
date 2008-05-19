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
      @field = ThinkingSphinx::Field.new([Object.stub_instance(:__stack => [])])
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
      @field.stub_method(:column_with_prefix => 'hello')
      @field.to_group_sql.should be_a_kind_of(Array)
    end
    
    after :each do
      ThinkingSphinx.unstub_method(:use_group_by_shortcut?)
    end
  end

  describe '#initialize' do
    it 'raises if no columns are provided so that configuration errors are easier to track down' do
      lambda {
        ThinkingSphinx::Field.new([])
      }.should raise_error(RuntimeError)
    end

    it 'raises if an element of the columns param is an integer - as happens when you use id instead of :id - so that configuration errors are easier to track down' do
      lambda {
        ThinkingSphinx::Field.new([1234])
      }.should raise_error(RuntimeError)
    end
  end
end
