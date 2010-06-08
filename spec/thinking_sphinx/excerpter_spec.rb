require 'spec/spec_helper'

describe ThinkingSphinx::Excerpter do
  before :each do
    @alpha      = Alpha.find(:first)
    @search     = mock 'search', :excerpt_for => 'excerpted value'
    @excerpter  = ThinkingSphinx::Excerpter.new(@search, @alpha)
  end
  
  it "should not respond to id" do
    @excerpter.should_not respond_to(:id)
  end
  
  describe '#method_missing' do
    it "should return the excerpt from Sphinx" do
      @excerpter.name.should == 'excerpted value'
    end
    
    it "should send through the instance class to excerpt_for" do
      @search.should_receive(:excerpt_for) do |string, model|
        model.should == Alpha
      end
      
      @excerpter.name
    end
    
    it "should use attribute methods for excerpts calls" do
      @search.should_receive(:excerpt_for) do |string, model|
        string.should == 'one'
      end
      
      @excerpter.name
    end
    
    it "should use instance methods for excerpts calls" do
      @search.should_receive(:excerpt_for) do |string, model|
        string.should == 'ONE'
      end
      
      @excerpter.big_name
    end
    
    it "should still raise an exception if no column or method exists" do
      lambda {
        @excerpter.foo
      }.should raise_error(NoMethodError)
    end
  end
end
