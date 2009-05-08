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
end
