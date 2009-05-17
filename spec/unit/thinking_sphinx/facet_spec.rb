require 'spec/spec_helper'

describe ThinkingSphinx::Facet do
  describe ".name_for" do
    it "should remove '_facet' from provided string and return a symbol" do
      ThinkingSphinx::Facet.name_for('attribute_facet').should == :attribute
    end

    it "should remove '_facet' from provided symbol" do
      ThinkingSphinx::Facet.name_for(:attribute_facet).should == :attribute
    end

    it "should return the name of the facet if a Facet is passed" do
      facet = ThinkingSphinx::Facet.new(
        ThinkingSphinx::Attribute.stub_instance(:unique_name => :attribute, :columns => ['attribute'])
      )
      ThinkingSphinx::Facet.name_for(facet).should == :attribute
    end

    it "should return 'class' for special case name 'class_crc'" do
      ThinkingSphinx::Facet.name_for(:class_crc).should == :class
    end

    it "should cycle" do
      ThinkingSphinx::Facet.name_for(ThinkingSphinx::Facet.attribute_name_for(:attribute)).should == :attribute
    end
  end

  describe ".attribute_name_for" do
    it "should append '_facet' to provided string" do
      ThinkingSphinx::Facet.attribute_name_for('attribute').should == 'attribute_facet'
    end

    it "should append '_facet' to provided symbol and return a string" do
      ThinkingSphinx::Facet.attribute_name_for(:attribute).should == 'attribute_facet'
    end

    it "should return 'class_crc' for special case attribute 'class'" do
      ThinkingSphinx::Facet.attribute_name_for(:class).should == 'class_crc'
    end

    it "should cycle" do
      ThinkingSphinx::Facet.attribute_name_for(ThinkingSphinx::Facet.name_for('attribute_facet')).should == 'attribute_facet'
    end
  end
  
  describe ".attribute_name_from_value" do
    it "should append _facet if the value is a string" do
      ThinkingSphinx::Facet.attribute_name_from_value('attribute', 'string').
        should == 'attribute_facet'
    end
    
    it "should not append _facet if the value isn't a string" do
      ThinkingSphinx::Facet.attribute_name_from_value('attribute', 1).
        should == 'attribute'
      ThinkingSphinx::Facet.attribute_name_from_value('attribute', Time.now).
        should == 'attribute'
      ThinkingSphinx::Facet.attribute_name_from_value('attribute', true).
        should == 'attribute'
      ThinkingSphinx::Facet.attribute_name_from_value('attribute', 1.23).
        should == 'attribute'
    end
    
    it "should append _facet is the value is an array of strings" do
      ThinkingSphinx::Facet.attribute_name_from_value('attribute', ['a', 'b']).
        should == 'attribute_facet'
    end
    
    it "should not append _facet if the value is an array of integers" do
      ThinkingSphinx::Facet.attribute_name_from_value('attribute', [1, 2]).
        should == 'attribute'
    end
  end
  
  describe ".translate?" do
    before :each do
      @index     = ThinkingSphinx::Index.new(Alpha)
      @source    = ThinkingSphinx::Source.new(@index)
      @attribute = ThinkingSphinx::Attribute.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:name)
      )
    end
    
    it "should return true if the property is a field" do
      field = ThinkingSphinx::Field.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:name)
      )
      
      ThinkingSphinx::Facet.translate?(field).should be_true
    end
    
    it "should return true if the property is a string attribute" do
      @attribute.stub_method(:type => :string)
      
      ThinkingSphinx::Facet.translate?(@attribute).should be_true
    end
    
    it "should return false if the property is an integer attribute" do
      @attribute.stub_method(:type => :integer)
      
      ThinkingSphinx::Facet.translate?(@attribute).should be_false
    end
    
    it "should return false if the property is a boolean attribute" do
      @attribute.stub_method(:type => :boolean)
      
      ThinkingSphinx::Facet.translate?(@attribute).should be_false
    end
    
    it "should return false if the property is a timestamp attribute" do
      @attribute.stub_method(:type => :datetime)
      
      ThinkingSphinx::Facet.translate?(@attribute).should be_false
    end
    
    it "should return false if the property is a float attribute" do
      @attribute.stub_method(:type => :float)
      
      ThinkingSphinx::Facet.translate?(@attribute).should be_false
    end
    
    it "should return false if the property is an MVA of integer values" do
      @attribute.stub_method(:type => :multi, :all_ints? => true)
      
      ThinkingSphinx::Facet.translate?(@attribute).should be_false
    end
    
    it "should return true if the property is an MVA of string values" do
      @attribute.stub_method(:type => :multi, :all_ints? => false)
      
      ThinkingSphinx::Facet.translate?(@attribute).should be_true
    end
  end
  
  describe "#translate?" do
    before :each do
      @index     = ThinkingSphinx::Index.new(Alpha)
      @source    = ThinkingSphinx::Source.new(@index)
      @attribute = ThinkingSphinx::Attribute.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:name)
      )
    end
    
    it "should return true if the property is a field" do
      field = ThinkingSphinx::Field.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:name)
      )
      
      ThinkingSphinx::Facet.new(field).translate?.should be_true
    end
    
    it "should return true if the property is a string attribute" do
      @attribute.stub_method(:type => :string)
      
      ThinkingSphinx::Facet.new(@attribute).translate?.should be_true
    end
    
    it "should return false if the property is an integer attribute" do
      @attribute.stub_method(:type => :integer)
      
      ThinkingSphinx::Facet.new(@attribute).translate?.should be_false
    end
    
    it "should return false if the property is a boolean attribute" do
      @attribute.stub_method(:type => :boolean)
      
      ThinkingSphinx::Facet.new(@attribute).translate?.should be_false
    end
    
    it "should return false if the property is a timestamp attribute" do
      @attribute.stub_method(:type => :datetime)
      
      ThinkingSphinx::Facet.new(@attribute).translate?.should be_false
    end
    
    it "should return false if the property is a float attribute" do
      @attribute.stub_method(:type => :float)
      
      ThinkingSphinx::Facet.new(@attribute).translate?.should be_false
    end
    
    it "should return false if the property is an MVA of integer values" do
      @attribute.stub_method(:type => :multi, :all_ints? => true)
      
      ThinkingSphinx::Facet.new(@attribute).translate?.should be_false
    end
    
    it "should return true if the property is an MVA of string values" do
      @attribute.stub_method(:type => :multi, :all_ints? => false)
      
      ThinkingSphinx::Facet.new(@attribute).translate?.should be_true
    end
  end
  
  describe "#attribute_name" do
    before :each do
      @index     = ThinkingSphinx::Index.new(Alpha)
      @source    = ThinkingSphinx::Source.new(@index)
      @attribute = ThinkingSphinx::Attribute.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:name)
      )
    end
    
    it "should return the attribute name if built off an integer attribute" do
      @attribute.stub_method(:type => :integer)
      
      ThinkingSphinx::Facet.new(@attribute).attribute_name.should == "name"
    end
    
    it "should return the attribute name if built off a boolean attribute" do
      @attribute.stub_method(:type => :boolean)
      
      ThinkingSphinx::Facet.new(@attribute).attribute_name.should == "name"
    end
    
    it "should return the attribute name if built off a float attribute" do
      @attribute.stub_method(:type => :float)
      
      ThinkingSphinx::Facet.new(@attribute).attribute_name.should == "name"
    end
    
    it "should return the attribute name if built off a timestamp attribute" do
      @attribute.stub_method(:type => :datetime)
      
      ThinkingSphinx::Facet.new(@attribute).attribute_name.should == "name"
    end
    
    it "should return the attribute name with _facet suffix if built off a string attribute" do
      @attribute.stub_method(:type => :string)
      
      ThinkingSphinx::Facet.new(@attribute).attribute_name.should == "name_facet"
    end
    
    it "should return the attribute name with _facet suffix if built off a field" do
      field = ThinkingSphinx::Field.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:name)
      )
      
      ThinkingSphinx::Facet.new(field).attribute_name.should == "name_facet"
    end
    
    it "should return the attribute name if build off an integer MVA" do
      @attribute.stub_method(:type => :multi, :all_ints? => true)
      
      ThinkingSphinx::Facet.new(@attribute).attribute_name.should == "name"
    end
    
    it "should return the attribute name with the _facet suffix if build off an non-integer MVA" do
      @attribute.stub_method(:type => :multi, :all_ints? => false)
      
      ThinkingSphinx::Facet.new(@attribute).attribute_name.should == "name_facet"
    end
  end
  
  describe "#type" do
    before :each do
      @index     = ThinkingSphinx::Index.new(Alpha)
      @source    = ThinkingSphinx::Source.new(@index)
    end
    
    it "should return :string if the property is a field" do
      field = ThinkingSphinx::Field.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:name)
      )
      
      ThinkingSphinx::Facet.new(field).type.should == :string
    end
    
    it "should return the attribute type if the property is an attribute" do
      attribute = ThinkingSphinx::Attribute.new(
        @source, ThinkingSphinx::Index::FauxColumn.new(:name)
      )
      attribute.stub_method(:type => :anything)
      
      ThinkingSphinx::Facet.new(attribute).type.should == :anything
    end
  end
end
