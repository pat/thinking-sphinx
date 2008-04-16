require 'spec/spec_helper'

describe ThinkingSphinx do
  it "should define indexes by default" do
    ThinkingSphinx.define_indexes?.should be_true
  end
  
  it "should disable index definition" do
    ThinkingSphinx.define_indexes = false
    ThinkingSphinx.define_indexes?.should be_false
  end
  
  it "should enable index definition" do
    ThinkingSphinx.define_indexes = false
    ThinkingSphinx.define_indexes?.should be_false
    ThinkingSphinx.define_indexes = true
    ThinkingSphinx.define_indexes?.should be_true
  end
  
  it "should index deltas by default" do
    ThinkingSphinx.deltas_enabled?.should be_true
  end
  
  it "should disable delta indexing" do
    ThinkingSphinx.deltas_enabled = false
    ThinkingSphinx.deltas_enabled?.should be_false
  end
  
  it "should enable delta indexing" do
    ThinkingSphinx.deltas_enabled = false
    ThinkingSphinx.deltas_enabled?.should be_false
    ThinkingSphinx.deltas_enabled = true
    ThinkingSphinx.deltas_enabled?.should be_true
  end
end