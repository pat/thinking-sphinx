require 'spec_helper'

describe ThinkingSphinx::Index::FauxColumn do  
  describe "coerce class method" do
    before :each do
      @column = stub('column')
      ThinkingSphinx::Index::FauxColumn.stub!(:new => @column)
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
  
  describe '#to_ary' do
    it "should return an array with the instance inside it" do
      subject.to_ary.should == [subject]
    end
  end
end
