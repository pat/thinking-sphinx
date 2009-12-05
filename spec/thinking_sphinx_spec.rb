require 'spec/spec_helper'

describe ThinkingSphinx do
  describe '.context' do
    it "should return a Context instance" do
      ThinkingSphinx.context.should be_a(ThinkingSphinx::Context)
    end
    
    it "should remember changes to the Context instance" do
      models = ThinkingSphinx.context.indexed_models
      
      ThinkingSphinx.context.indexed_models.replace([:model])
      ThinkingSphinx.context.indexed_models.should == [:model]
      
      ThinkingSphinx.context.indexed_models.replace(models)
    end
  end
  
  describe '.define_indexes?' do
    it "should define indexes by default" do
      ThinkingSphinx.define_indexes?.should be_true
    end
  end
  
  describe '.define_indexes=' do
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
  end
  
  describe '.deltas_enabled?' do
    it "should index deltas by default" do
      ThinkingSphinx.deltas_enabled = nil
      ThinkingSphinx.deltas_enabled?.should be_true
    end
  end
  
  describe '.deltas_enabled=' do
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
  
  describe '.updates_enabled?' do
    it "should update indexes by default" do
      ThinkingSphinx.updates_enabled = nil
      ThinkingSphinx.updates_enabled?.should be_true
    end
  end
  
  describe '.updates_enabled=' do
    it "should disable index updating" do
      ThinkingSphinx.updates_enabled = false
      ThinkingSphinx.updates_enabled?.should be_false
    end
  
    it "should enable index updating" do
      ThinkingSphinx.updates_enabled = false
      ThinkingSphinx.updates_enabled?.should be_false
      ThinkingSphinx.updates_enabled = true
      ThinkingSphinx.updates_enabled?.should be_true
    end
  end
  
  describe '.sphinx_running?' do
    it "should always say Sphinx is running if flagged as being on a remote machine" do
      ThinkingSphinx.remote_sphinx = true
      ThinkingSphinx.stub!(:sphinx_running_by_pid? => false)
    
      ThinkingSphinx.sphinx_running?.should be_true
    end
  
    it "should actually pay attention to Sphinx if not on a remote machine" do
      ThinkingSphinx.remote_sphinx = false
      ThinkingSphinx.stub!(:sphinx_running_by_pid? => false)
      ThinkingSphinx.sphinx_running?.should be_false
    
      ThinkingSphinx.stub!(:sphinx_running_by_pid? => true)
      ThinkingSphinx.sphinx_running?.should be_true
    end
  end
  
  describe '.version' do
    it "should return the version from the stored YAML file" do
      version = Jeweler::VersionHelper.new(
        File.join(File.dirname(__FILE__), '..')
      ).to_s
      
      ThinkingSphinx.version.should == version
    end
  end
end
