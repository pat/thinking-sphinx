require 'spec/spec_helper'

describe ThinkingSphinx::Index::FauxColumn do  
  describe "coerce class method" do
    before :each do
      @column = ThinkingSphinx::Index::FauxColumn.stub_instance
      ThinkingSphinx::Index::FauxColumn.stub_method(:new => @column)
    end
    
    it "should return a single faux column if passed a string" do
      ThinkingSphinx::Index::FauxColumn.coerce("string").should == @column
    end
    
    it "should return a single faux column if passed a symbol" do
      ThinkingSphinx::Index::FauxColumn.coerce(:string).should == @column
    end
    
    it "should return an array of faux columns if passed an array of strings" do
      ThinkingSphinx::Index::FauxColumn.coerce(["one", "two"]).should == [
        @column, @column
      ]
    end
    
    it "should return an array of faux columns if passed an array of symbols" do
      ThinkingSphinx::Index::FauxColumn.coerce([:one, :two]).should == [
        @column, @column
      ]
    end
  end
end