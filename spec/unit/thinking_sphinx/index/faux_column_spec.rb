require 'spec/spec_helper'

describe ThinkingSphinx::Index::FauxColumn do
  it "should use the last argument as the name, with preceeding ones going into the stack" do
    #
  end
  
  it "should access the name through __name" do
    #
  end
  
  it "should access the stack through __stack" do
    #
  end
  
  it "should return true from is_string? if the name is a string and the stack is empty" do
    #
  end
  
  describe "method_missing calls with no arguments" do
    it "should push any further method calls into name, and the old name goes into the stack" do
      #
    end
    
    it "should return itself" do
      #
    end
  end
  
  describe "method_missing calls with one argument" do
    it "should act as if calling method missing with method, then argument" do
      #
    end
  end
  
  describe "method_missing calls with more than one argument" do
    it "should return a collection of Faux Columns sharing the same stack, but with each argument as the name" do
      #
    end
  end
end