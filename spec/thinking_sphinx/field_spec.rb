require 'spec_helper'

describe ThinkingSphinx::Field do
  before :each do
    @index     = ThinkingSphinx::Index.new(Alpha)
    @source    = ThinkingSphinx::Source.new(@index)
  end
  
  describe '#initialize' do
    it 'raises if no columns are provided so that configuration errors are easier to track down' do
      lambda {
        ThinkingSphinx::Field.new(@source, [])
      }.should raise_error(RuntimeError)
    end

    it 'raises if an element of the columns param is an integer - as happens when you use id instead of :id - so that configuration errors are easier to track down' do
      lambda {
        ThinkingSphinx::Field.new(@source, [1234])
      }.should raise_error(RuntimeError)
    end
  end
  
  describe "unique_name method" do
    before :each do
      @field = ThinkingSphinx::Field.new @source, [
        stub('column', :__stack => [], :__name => "col_name")
      ]
    end
    
    it "should use the alias if there is one" do
      @field.alias = "alias"
      @field.unique_name.should == "alias"
    end
    
    it "should use the alias if there's multiple columns" do
      @field.columns << stub('column', :__stack => [], :__name => "col_name")
      @field.unique_name.should be_nil
      
      @field.alias = "alias"
      @field.unique_name.should == "alias"
    end
    
    it "should use the column name if there's no alias and just one column" do
      @field.unique_name.should == "col_name"
    end
  end
  
  describe '#to_select_sql' do
    it "should return nil if polymorphic association data does not exist" do
      field = ThinkingSphinx::Field.new(@source,
        [ThinkingSphinx::Index::FauxColumn.new(:source, :name)],
        :as => :source_name
      )
      
      field.to_select_sql.should be_nil
    end
  end

  describe "prefixes method" do
    it "should default to false" do
      @field = ThinkingSphinx::Field.new(
        @source, [stub('column', :__stack => [])]
      )
      @field.prefixes.should be_false
    end
    
    it "should be true if the corresponding option is set" do
      @field = ThinkingSphinx::Field.new(
        @source, [stub('column', :__stack => [])], :prefixes => true
      )
      @field.prefixes.should be_true
    end
  end
  
  describe "infixes method" do
    it "should default to false" do
      @field = ThinkingSphinx::Field.new(
        @source, [stub('column', :__stack => [])]
      )
      @field.infixes.should be_false
    end
    
    it "should be true if the corresponding option is set" do
      @field = ThinkingSphinx::Field.new(
        @source, [stub('column', :__stack => [])], :infixes => true
      )
      @field.infixes.should be_true
    end
  end
  
  describe "is_many? method" do
    before :each do
      @assoc_a = stub('assoc', :is_many? => true)
      @assoc_b = stub('assoc', :is_many? => true)
      @assoc_c = stub('assoc', :is_many? => true)
      
      @field = ThinkingSphinx::Field.new(
        @source, [ThinkingSphinx::Index::FauxColumn.new(:col_name)]
      )
      @field.associations = {
        :a => @assoc_a, :b => @assoc_b, :c => @assoc_c
      }
    end
    
    it "should return true if all associations return true to is_many?" do
      @field.send(:is_many?).should be_true
    end
    
    it "should return true if one association returns true to is_many?" do
      @assoc_b.stub!(:is_many? => false)
      @assoc_c.stub!(:is_many? => false)
      
      @field.send(:is_many?).should be_true
    end
    
    it "should return false if all associations return false to is_many?" do
      @assoc_a.stub!(:is_many? => false)
      @assoc_b.stub!(:is_many? => false)
      @assoc_c.stub!(:is_many? => false)
      
      @field.send(:is_many?).should be_false
    end
  end
end
