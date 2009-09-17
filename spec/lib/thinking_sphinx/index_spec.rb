require 'spec/spec_helper'

describe ThinkingSphinx::Index do
  describe "prefix_fields method" do
    before :each do
      @index = ThinkingSphinx::Index.new(Person)
      
      @field_a = stub('field', :prefixes => true)
      @field_b = stub('field', :prefixes => false)
      @field_c = stub('field', :prefixes => true)
      
      @index.stub!(:fields => [@field_a, @field_b, @field_c])
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
      
      @field_a = stub('field', :infixes => true)
      @field_b = stub('field', :infixes => false)
      @field_c = stub('field', :infixes => true)
      
      @index.stub!(:fields => [@field_a, @field_b, @field_c])
    end
    
    it "should return fields that are flagged as infixed" do
      @index.infix_fields.should include(@field_a)
      @index.infix_fields.should include(@field_c)
    end
    
    it "should not return fields that aren't flagged as infixed" do
      @index.infix_fields.should_not include(@field_b)
    end
  end
end
