require 'spec/spec_helper'

describe ThinkingSphinx::Index do
  describe "prefix_fields method" do
    before :each do
      @index = ThinkingSphinx::Index.new(Person)
      
      @field_a = ThinkingSphinx::Field.stub_instance(:prefixes => true)
      @field_b = ThinkingSphinx::Field.stub_instance(:prefixes => false)
      @field_c = ThinkingSphinx::Field.stub_instance(:prefixes => true)
      
      @index.stub_method(:fields => [@field_a, @field_b, @field_c])
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
      
      @index.stub_method(:fields => [@field_a, @field_b, @field_c])
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
